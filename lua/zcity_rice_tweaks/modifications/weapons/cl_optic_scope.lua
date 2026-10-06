-- 倍镜渲染重写: 基于镜片网格UV的真实光学投影 (类EFT画中画瞄具)
-- 替换 homigrad_base 的 SWEP:DoRT, 找不到镜片网格时回退原实现

local ZCITY_INITALIZED = ZCityRiceTweaks.ZCITY_INITALIZED

local CVAR_ENABLED = CreateClientConVar("zc_rice_scope_enabled", "1", true, false, "新版倍镜渲染 (0 = 使用原版)", 0, 1)
local CVAR_RT_SIZE = CreateClientConVar("zc_rice_scope_rtsize", "1024", true, false, "倍镜镜内画面分辨率 (正方形边长)", 256, 2048)
local CVAR_CHEAP = CreateClientConVar("zc_rice_scope_cheap", "0", true, false, "廉价倍镜: 放大主画面代替第二次 RenderView", 0, 1)
local CVAR_CHEAP_SS = CreateClientConVar("zc_rice_scope_cheap_ss", "150", true, false, "廉价倍镜开镜时主画面渲染分辨率百分比 (100 = 不超采样)", 100, 200)
local CVAR_SHADOW = CreateClientConVar("zc_rice_scope_shadow", "2.5", true, false, "镜内阴影随眼位偏移的放大系数", 0, 10)
local CVAR_DEBUG = CreateClientConVar("zc_rice_scope_debug", "0", false, false, "", 0, 1)

-- 每帧把镜片材质的 $basetexture 指向此RT, 回退原版时原版会改回自己的RT
local RT, RT_SIZE, RT_HALF

-- RT名字带尺寸, 换分辨率时引擎会创建新RT (旧的无法释放, 正常使用切换次数很少)
local function setRTSize(size)
    RT_SIZE = math.Clamp(math.floor(tonumber(size) or 1024), 256, 2048)
    RT_HALF = RT_SIZE / 2
    RT = GetRenderTargetEx("zc_rice_scope_rt_" .. RT_SIZE,
        RT_SIZE, RT_SIZE,
        RT_SIZE_LITERAL,
        MATERIAL_RT_DEPTH_SEPARATE,
        bit.bor(4, 8, 256),
        0,
        IMAGE_FORMAT_BGR888
    )
end

setRTSize(CVAR_RT_SIZE:GetInt())

cvars.AddChangeCallback("zc_rice_scope_rtsize", function(_, _, new)
    setRTSize(new)
end, "ZCityRiceTweaks_OpticScope")

local MAT_SHADOW = CreateMaterial("zc_rice_scope_shadow", "UnlitGeneric", {
    ["$basetexture"] = "vgui/white",
    ["$vertexcolor"] = 1,
    ["$vertexalpha"] = 1,
    ["$translucent"] = 1,
    ["$ignorez"] = 1
})

local FALLBACK_LENS_MAT = Material("huy-glass")

-- 已知瞄具的真实倍率 {最低倍率, 最高倍率}, ZoomFOV 在 FOVMax..FOVMin 间对数映射
local MAGNIFICATION = {
    optic2 = {1, 4},     -- Burris Fullfield TAC30 1-4x
    optic3 = {3, 20},    -- Valday PS-320 1-6x (实际按 3-20 的游戏手感)
    optic4 = {4, 4},     -- ПСО-1М2 4x
    optic5 = {1, 6},     -- Vortex Razor HD 1-6x
    optic6 = {6.5, 20},  -- Leupold Mark 4 LR 6.5-20x
    optic7 = {4, 4},     -- SIG Bravo4 4x
    optic8 = {4, 4},     -- Leupold HAMR 4x
    optic9 = {4, 4},     -- ACOG TA01 4x
    optic11 = {4, 4},    -- ПСО-1М2-1 4x
    optic12 = {6, 6},    -- EOTech Vudu (使用4x分划)
    optic13 = {5.5, 5.5},-- ПАГ-17
    optic14 = {1, 4}     -- Elcan Specter DR 1-4x
}

local lensCache = {}
local lensMissTime = {}

local function getMagnification(wep, attName, zoom_fov)
    zoom_fov = zoom_fov or wep.ZoomFOV or 10

    local fov_min, fov_max = wep.FOVMin or zoom_fov, wep.FOVMax or zoom_fov
    local mag = MAGNIFICATION[attName]

    if not mag then
        return math.Clamp(40 / zoom_fov, 1, 25)
    end

    if fov_max - fov_min < 0.01 then return mag[2] end

    local frac = math.Clamp(math.log(fov_max / zoom_fov) / math.log(fov_max / fov_min), 0, 1)

    return mag[1] * (mag[2] / mag[1]) ^ frac
end

-- 3x3 线性方程求解 (Cramer)
local function solve3(a, b)
    local function det(m)
        return m[1][1] * (m[2][2] * m[3][3] - m[2][3] * m[3][2])
            - m[1][2] * (m[2][1] * m[3][3] - m[2][3] * m[3][1])
            + m[1][3] * (m[2][1] * m[3][2] - m[2][2] * m[3][1])
    end

    local d = det(a)
    if math.abs(d) < 1e-9 then return end

    local res = {}

    for col = 1, 3 do
        local m = {{a[1][1], a[1][2], a[1][3]}, {a[2][1], a[2][2], a[2][3]}, {a[3][1], a[3][2], a[3][3]}}

        for row = 1, 3 do m[row][col] = b[row] end

        res[col] = det(m) / d
    end

    return res
end

-- 从模型网格中找出贴了RT材质的镜片, 拟合 局部坐标 -> UV 的仿射映射
local function buildLens(model, lensMat)
    local meshes, binds = util.GetModelMeshes(model:GetModel(), 0, 0)
    if not meshes then return end

    local wanted = {}
    local lensName = lensMat and lensMat:GetName() or ""

    wanted[lensName] = true
    wanted["effects/arc9/rt"] = true
    wanted["effects/arc9/rtglass"] = true

    -- 子材质覆盖 (如 optic13 把 glass_d 换成 rtglass)
    local materials = model:GetMaterials()

    for i, name in ipairs(materials) do
        local sub = model:GetSubMaterial(i - 1)

        if sub ~= "" and wanted[sub] then wanted[name] = true end
    end

    local lensMesh

    for _, m in ipairs(meshes) do
        if wanted[m.material] then
            lensMesh = m

            break
        end
    end

    if not lensMesh or #lensMesh.triangles < 3 then return end

    -- 网格顶点在绑定姿态空间, 世界坐标 = 骨骼矩阵 * 绑定姿态矩阵 * 顶点
    local firstWeight = lensMesh.triangles[1].weights and lensMesh.triangles[1].weights[1]
    local bone = firstWeight and firstWeight.bone or 0
    local bind = binds and binds[bone] and binds[bone].matrix

    local mins, maxs = Vector(math.huge, math.huge, math.huge), Vector(-math.huge, -math.huge, -math.huge)

    for _, vert in ipairs(lensMesh.triangles) do
        mins = Vector(math.min(mins.x, vert.pos.x), math.min(mins.y, vert.pos.y), math.min(mins.z, vert.pos.z))
        maxs = Vector(math.max(maxs.x, vert.pos.x), math.max(maxs.y, vert.pos.y), math.max(maxs.z, vert.pos.z))
    end

    local size = maxs - mins
    local normalAxis = 1

    if size[2] < size[normalAxis] then normalAxis = 2 end
    if size[3] < size[normalAxis] then normalAxis = 3 end

    local a1, a2 = normalAxis == 1 and 2 or 1, normalAxis == 3 and 2 or 3
    local center = (mins + maxs) * 0.5

    -- 最小二乘: u = cu0 + cu1 * p[a1] + cu2 * p[a2] (相对中心)
    local ata = {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}}
    local atu, atv = {0, 0, 0}, {0, 0, 0}

    for _, vert in ipairs(lensMesh.triangles) do
        local row = {1, vert.pos[a1] - center[a1], vert.pos[a2] - center[a2]}

        for i = 1, 3 do
            for j = 1, 3 do ata[i][j] = ata[i][j] + row[i] * row[j] end

            atu[i] = atu[i] + row[i] * vert.u
            atv[i] = atv[i] + row[i] * vert.v
        end
    end

    local cu, cv = solve3(ata, atu), solve3(ata, atv)
    if not cu or not cv then return end

    -- 逆映射: Δ(u, v) -> Δ局部坐标
    local det = cu[2] * cv[3] - cu[3] * cv[2]
    if math.abs(det) < 1e-9 then return end

    -- 缺失材质的玻璃层(___error)会把棋盘格盖在RT上, 直接隐藏所有缺失材质的槽位
    -- (ACOG 的玻璃网格是贯穿镜筒的长条, 按位置筛选会漏掉)
    local hideSlots = {}
    local lensRadius = (size[a1] + size[a2]) * 0.25

    for i, name in ipairs(materials) do
        if not wanted[name] and Material(name):IsError() then hideSlots[#hideSlots + 1] = i - 1 end
    end

    local lens = {
        HideSlots = hideSlots,
        Bone = bone,
        Bind = bind,
        Center = center,
        A1 = a1,
        A2 = a2,
        Normal = normalAxis,
        Cu = cu,
        Cv = cv,
        -- 局部坐标中 u, v 各增加1时的位移
        DU = {cv[3] / det, -cv[2] / det},
        DV = {-cu[3] / det, cu[2] / det},
        Radius = lensRadius,
        UVCenter = {cu[1], cv[1]}
    }

    return lens
end

local function getLens(model, lensMat)
    local key = model:GetModel()
    local cached = lensCache[key]

    if cached then return cached end
    if lensMissTime[key] and lensMissTime[key] > CurTime() then return end

    local lens = buildLens(model, lensMat)

    if lens then
        lensCache[key] = lens
    else
        lensMissTime[key] = CurTime() + 2
    end

    return lens
end

local function localAxis(lens, a1Val, a2Val, normalVal)
    local v = Vector(0, 0, 0)

    v[lens.A1] = a1Val
    v[lens.A2] = a2Val
    v[lens.Normal] = normalVal or 0

    return v
end

-- 预生成环形阴影顶点 (单位圆)
local SEGMENTS = 64
local ringCos, ringSin = {}, {}

for i = 0, SEGMENTS do
    local a = i / SEGMENTS * math.pi * 2

    ringCos[i] = math.cos(a)
    ringSin[i] = math.sin(a)
end

-- 画一个从 inner(alpha=a0) 到 outer(alpha=a1) 渐变的圆环
local function drawRing(cx, cy, inner, outer, a0, a1)
    mesh.Begin(MATERIAL_QUADS, SEGMENTS)

    for i = 0, SEGMENTS - 1 do
        local c0, s0, c1, s1 = ringCos[i], ringSin[i], ringCos[i + 1], ringSin[i + 1]

        mesh.Position(Vector(cx + c0 * inner, cy + s0 * inner, 0))
        mesh.Color(0, 0, 0, a0)
        mesh.AdvanceVertex()

        mesh.Position(Vector(cx + c0 * outer, cy + s0 * outer, 0))
        mesh.Color(0, 0, 0, a1)
        mesh.AdvanceVertex()

        mesh.Position(Vector(cx + c1 * outer, cy + s1 * outer, 0))
        mesh.Color(0, 0, 0, a1)
        mesh.AdvanceVertex()

        mesh.Position(Vector(cx + c1 * inner, cy + s1 * inner, 0))
        mesh.Color(0, 0, 0, a0)
        mesh.AdvanceVertex()
    end

    mesh.End()
end

local function drawShadow(cx, cy, radius, softness)
    render.SetMaterial(MAT_SHADOW)

    -- 软边 + 外部完全遮黑
    drawRing(cx, cy, radius * (1 - softness), radius, 0, 255)
    drawRing(cx, cy, radius, RT_SIZE * 3, 255, 255)
end

local function drawReticle(wep, cx, cy, mag, attData)
    local base = wep.sizeperekrestie * RT_SIZE / 512
    local size

    if wep.perekrestieSize then
        -- 第二焦平面: 分划大小不随倍率变化
        size = base / 4
    else
        -- 第一焦平面: 分划随倍率缩放, 在最低倍率时与原版一致
        local fov_max = wep.FOVMax or wep.ZoomFOV
        local magMin = getMagnification(wep, wep.riceScopeAttName, fov_max)

        size = base / (fov_max / 3) * (mag / magMin)
    end

    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(wep.perekrestie)
    surface.DrawTexturedRectRotated(cx, cy, size, size, 0)
end

local OriginalDoRT
local hg_show_hitposmuzzle = GetConVar("hg_show_hitposmuzzle")

-- 廉价倍镜: 主视图画完半透明物体后拷贝屏幕, 镜内直接放大这张图
-- 拷贝前隐藏自己的武器(否则镜内会拍到瞄具本身), 拷贝后再画回来
local captureRT, captureW, captureH
local captureMat = CreateMaterial("zc_rice_scope_capture", "UnlitGeneric", {
    ["$basetexture"] = "vgui/white",
    ["$ignorez"] = 1
})
local captureFrame = -10
local captureView
local cheapWeapon, cheapFrame = nil, -10
local suppressWeapon, suppressedDraw
-- 拷贝前被跳过的本地玩家身体 {self, ent, flags}, 拷贝后补画
local suppressedBody
local cheapReady = false

-- 尺寸跟随当前视口 (超采样时大于屏幕)
local function getCaptureRT(w, h)
    if w ~= captureW or h ~= captureH then
        captureW, captureH = w, h
        captureRT = GetRenderTargetEx("zc_rice_scope_capture_" .. w .. "x" .. h,
            w, h,
            RT_SIZE_LITERAL,
            MATERIAL_RT_DEPTH_NONE,
            bit.bor(4, 8, 256),
            0,
            IMAGE_FORMAT_RGB888
        )
        captureMat:SetTexture("$basetexture", captureRT)
    end

    return captureRT
end

-- 把主画面中镜内相机看到的区域贴满RT (同一相机原点, 纯旋转, 小FOV下单个四边形足够)
local function drawCaptured(camAng, fov)
    local f, r, u = camAng:Forward(), camAng:Right(), camAng:Up()
    local tanHalf = math.tan(math.rad(fov / 2))

    local vAng = captureView.angles
    local vf, vr, vu = vAng:Forward(), vAng:Right(), vAng:Up()
    local vTanX = math.tan(math.rad(captureView.fov / 2))
    local vTanY = vTanX / (captureView.aspect or captureW / captureH)

    local poly = {}

    for i, corner in ipairs({{0, 0}, {1, 0}, {1, 1}, {0, 1}}) do
        local dir = f + r * ((corner[1] * 2 - 1) * tanHalf) - u * ((corner[2] * 2 - 1) * tanHalf)
        local depth = dir:Dot(vf)

        if depth < 0.1 then return end

        poly[i] = {
            x = corner[1] * RT_SIZE,
            y = corner[2] * RT_SIZE,
            u = 0.5 + 0.5 * dir:Dot(vr) / depth / vTanX,
            v = 0.5 - 0.5 * dir:Dot(vu) / depth / vTanY
        }
    end

    cam.Start2D()
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(captureMat)
        surface.DrawPoly(poly)
    cam.End2D()
end

-- 部分 GMod 版本没有导出 VIEW_* 枚举
local VIEW_MAIN = VIEW_MAIN or 0

local function isMainView(depth, skybox, sky3d)
    return not depth and not skybox and not sky3d and render.GetViewSetup().viewid == VIEW_MAIN
end

hook.Add("PreDrawOpaqueRenderables", "ZCityRiceTweaks_CheapScope", function(depth, skybox, sky3d)
    if not isMainView(depth, skybox, sky3d) or RENDERING_SCOPE then return end

    suppressWeapon, suppressedDraw, suppressedBody = nil, nil, nil

    if not cheapReady or not CVAR_CHEAP:GetBool() or FrameNumber() - cheapFrame > 2 or not IsValid(cheapWeapon) then return end

    suppressWeapon = cheapWeapon
end)

hook.Add("PostDrawTranslucentRenderables", "ZCityRiceTweaks_CheapScope", function(depth, skybox, sky3d)
    local wep = suppressWeapon
    if not wep or not isMainView(depth, skybox, sky3d) then return end

    suppressWeapon = nil

    -- GetViewSetup 的 width/height 会被夹到屏幕尺寸, ScrW/ScrH 才反映当前RT(超采样时为大RT)
    captureView = render.GetViewSetup()
    render.CopyRenderTargetToTexture(getCaptureRT(ScrW(), ScrH()))
    captureFrame = FrameNumber()

    -- 身体补画会经 DrawPlayerRagdoll -> RenderWeapons 把武器一起画回来, 否则单独补画武器
    local body = suppressedBody

    suppressedBody = nil

    -- 经实体 DrawModel 走一次引擎 RenderOverride; 直接调 hg.renderOverride 会在其内部 DrawModel 时再递归一次, 身体画两遍
    local bodyEnt = body and (IsValid(body[2]) and body[2] or body[1])

    if IsValid(bodyEnt) then
        bodyEnt:DrawModel(body[3])
    elseif suppressedDraw and IsValid(wep) then
        suppressedDraw(wep)
    end

    suppressedDraw = nil
end)

local function NewDoRT(self)
    if not CVAR_ENABLED:GetBool() then return OriginalDoRT(self) end

    local sight, attData = self:HasAttachment("sight", "optic")
    local model = attData and self.modelAtt and self.modelAtt.sight

    if not IsValid(model) or not self.sizeperekrestie then return OriginalDoRT(self) end

    local lensMat = self.mat or FALLBACK_LENS_MAT
    local lens = getLens(model, lensMat)

    if not lens then return OriginalDoRT(self) end

    LOW_RENDER = nil

    local owner = self:GetOwner()
    local gun = self:GetWeaponEntity()

    if not IsValid(owner) or not self:GetMuzzleAtt(gun, true) then return end

    self.isscoping = true
    self.riceScopeAttName = self.attachments and self.attachments.sight and self.attachments.sight[1]

    local _, aimAng = self:GetTrace(true, nil, nil, true)
    local aimDir = aimAng:Forward()
    local view = render.GetViewSetup(true)
    local eye = view.origin

    for _, slot in ipairs(lens.HideSlots) do
        if model:GetSubMaterial(slot) == "" then model:SetSubMaterial(slot, "null") end
    end

    local boneMatrix = model:GetBoneMatrix(lens.Bone)
    if not boneMatrix then return OriginalDoRT(self) end

    -- 骨骼矩阵已包含 SetModelScale
    local meshToWorld = lens.Bind and boneMatrix * lens.Bind or boneMatrix
    local worldToMesh = meshToWorld:GetInverse()
    if not worldToMesh then return OriginalDoRT(self) end

    local meshOrigin = meshToWorld:GetTranslation()

    local function toWorld(localPos)
        return meshToWorld * localPos
    end

    local function toWorldDir(localDir)
        return meshToWorld * localDir - meshOrigin
    end

    local lensCenter = toWorld(lens.Center)
    local lensNormal = toWorldDir(localAxis(lens, 0, 0, 1))
    lensNormal:Normalize()

    -- 瞄准轴与镜片平面交点 = 分划中心在镜片上的位置
    local denom = aimDir:Dot(lensNormal)

    lensMat:SetTexture("$basetexture", RT)

    render.PushRenderTarget(RT)
    render.Clear(0, 0, 0, 255, true, true)

    if math.abs(denom) < 0.2 then
        render.PopRenderTarget()

        return
    end

    local t = (lensCenter - eye):Dot(lensNormal) / denom
    local hit = eye + aimDir * t
    local dist = (hit - eye):Length()

    -- 交点转镜片局部 -> UV
    local hitLocal = worldToMesh * hit
    local d1, d2 = hitLocal[lens.A1] - lens.Center[lens.A1], hitLocal[lens.A2] - lens.Center[lens.A2]
    local hitU = lens.Cu[1] + lens.Cu[2] * d1 + lens.Cu[3] * d2
    local hitV = lens.Cv[1] + lens.Cv[2] * d1 + lens.Cv[3] * d2

    -- 一个UV单位在世界中的位移
    local worldDU = toWorldDir(localAxis(lens, lens.DU[1], lens.DU[2]))
    local worldDV = toWorldDir(localAxis(lens, lens.DV[1], lens.DV[2]))

    local cx, cy = hitU * RT_SIZE, hitV * RT_SIZE
    local lensCx, lensCy = lens.UVCenter[1] * RT_SIZE, lens.UVCenter[2] * RT_SIZE
    local lensRadiusPx = lens.Radius / ((lens.DU[1] ^ 2 + lens.DU[2] ^ 2) ^ 0.5) * RT_SIZE

    -- 眼位偏离镜片中心太多, 只剩黑
    local offX, offY = cx - lensCx, cy - lensCy

    if offX * offX + offY * offY > (lensRadiusPx * 1.6) ^ 2 then
        render.PopRenderTarget()

        return
    end

    local mag = getMagnification(self, self.riceScopeAttName)

    -- 镜片上一个RT像素对应的视角正切, 除以倍率得到镜内相机的像素正切
    local pxTan = worldDU:Length() / RT_SIZE / dist / mag
    local fov = math.deg(math.atan(pxTan * RT_HALF)) * 2

    -- 镜内相机: 中心像素(RT_HALF)相对分划中心(cx, cy)偏移, 旋转相机补偿
    local right = worldDU:GetNormalized()
    local down = worldDV:GetNormalized()
    local camDir = aimDir + right * (RT_HALF - cx) * pxTan + down * (RT_HALF - cy) * pxTan
    camDir:Normalize()

    local camUp = -down
    camUp = (camUp - camDir * camUp:Dot(camDir)):GetNormalized()

    local camAng = camDir:AngleEx(camUp)

    if CVAR_DEBUG:GetBool() then
        ZCityRiceTweaks.ScopeDebug = {
            Fov = fov, Mag = mag, Dist = dist, Cx = cx, Cy = cy, LensCx = lensCx, LensCy = lensCy,
            LensRadiusPx = lensRadiusPx, Mirrored = camDir:Cross(camUp):Dot(right) < 0
        }
    end

    -- 相机原点放在眼睛位置 (防穿墙沿用原版trace)
    local tr = util.QuickTrace(owner:EyePos(), eye - owner:EyePos(), {owner, owner.FakeRagdoll})
    local origin = owner:InVehicle() and eye or tr.HitPos

    local cheap = CVAR_CHEAP:GetBool()

    if cheap then
        cheapWeapon, cheapFrame = self, FrameNumber()
    end

    RENDERING_SCOPE = self

    local usedCheap = cheap and cheapReady and captureFrame == FrameNumber() and captureView ~= nil

    if CVAR_DEBUG:GetBool() then ZCityRiceTweaks.ScopeDebug.Cheap = usedCheap end

    if usedCheap then
        drawCaptured(camAng, fov)
    else
        render.RenderView({
            x = 0,
            y = 0,
            w = RT_SIZE,
            h = RT_SIZE,
            origin = origin,
            angles = camAng,
            fov = fov,
            aspect = 1,
            znear = 1,
            drawviewmodel = false,
            drawhud = false,
            dopostprocess = false,
            bloomtone = false
        })
    end

    local oldClip = DisableClipping(true)

    cam.Start2D()
        render.PushFilterMin(TEXFILTER.ANISOTROPIC)
        render.PushFilterMag(TEXFILTER.ANISOTROPIC)

        drawReticle(self, cx, cy, mag, attData)

        if self.SightDrawFunc then self:SightDrawFunc() end
        if attData.SightDrawFunc then attData.SightDrawFunc(self) end

        render.PopFilterMin()
        render.PopFilterMag()

        -- 视场光阑: 以分划中心为圆心, 半径略小于镜片
        drawShadow(cx, cy, lensRadiusPx * 0.97, 0.06)

        -- 出瞳阴影: 眼睛偏离光轴时, 阴影从偏移方向压入
        local shadowMul = CVAR_SHADOW:GetFloat()
        local sx, sy = lensCx - offX * shadowMul, lensCy - offY * shadowMul
        local offLen = (offX * offX + offY * offY) ^ 0.5 / lensRadiusPx

        drawShadow(sx, sy, lensRadiusPx * (1.15 + offLen * 0.3), 0.35 + math.min(offLen, 1) * 0.3)

        -- 镜片边缘暗角
        drawShadow(lensCx, lensCy, lensRadiusPx, 0.25)

        if hg_show_hitposmuzzle and hg_show_hitposmuzzle:GetBool() and LocalPlayer():IsAdmin() then
            surface.SetDrawColor(255, 0, 0)
            surface.DrawRect(cx - 2, cy - 2, 4, 4)
        end
    cam.End2D()

    DisableClipping(oldClip)

    RENDERING_SCOPE = false
    render.PopRenderTarget()
end

-- 包一层 hg.RenderWeapons: 廉价倍镜拷贝屏幕前跳过自己手上的武器, 并取出内部 DrawWorldModel 供稍后补画
local function installCheapScope()
    local current = hg.RenderWeapons
    if not current then return end

    local original = current == ZCityRiceTweaks.CheapRenderWeapons and ZCityRiceTweaks.OriginalRenderWeapons or current
    local drawWorldModel

    for i = 1, 60 do
        local name, value = debug.getupvalue(original, i)
        if not name then break end

        if name == "DrawWorldModel" then
            drawWorldModel = value

            break
        end
    end

    if not isfunction(drawWorldModel) then return end

    local function cheapRenderWeapons(ent, owner)
        local wep = suppressWeapon

        if not wep or owner ~= wep:GetOwner() then return original(ent, owner) end

        suppressedDraw = drawWorldModel

        local prev = RENDERING_SCOPE
        RENDERING_SCOPE = wep
        original(ent, owner)
        RENDERING_SCOPE = prev
    end

    ZCityRiceTweaks.OriginalRenderWeapons = original
    ZCityRiceTweaks.CheapRenderWeapons = cheapRenderWeapons
    hg.RenderWeapons = cheapRenderWeapons

    return true
end

-- 包一层 hg.renderOverride (所有玩家/布偶的 RenderOverride 都动态调用它):
-- 镜内 RenderView 时不画持枪者自己, 廉价倍镜拷贝前跳过自己的身体(低倍镜会拍到手), 拷贝后补画
local function installBodyHide()
    local current = hg.renderOverride
    if not current then return end

    local original = current == ZCityRiceTweaks.ScopeRenderOverride and ZCityRiceTweaks.OriginalRenderOverride or current

    local function scopeRenderOverride(self, ent, flags)
        if RENDERING_SCOPE and IsValid(RENDERING_SCOPE) and self == RENDERING_SCOPE:GetOwner() then return end

        local wep = suppressWeapon

        if wep and self == wep:GetOwner() then
            if bit.band(flags, STUDIO_RENDER) == STUDIO_RENDER then suppressedBody = {self, ent, flags} end

            return
        end

        return original(self, ent, flags)
    end

    ZCityRiceTweaks.OriginalRenderOverride = original
    ZCityRiceTweaks.ScopeRenderOverride = scopeRenderOverride
    hg.renderOverride = scopeRenderOverride

    return true
end

-- 廉价倍镜超采样: 开镜时主画面画进更大的RT, 镜内放大的是高分辨率拷贝, 屏幕上再缩回原尺寸
-- z-city 的 RenderScene 钩子(jopa)每帧把 renderView.w/h 写成屏幕尺寸, 且 GMod 没有 debug.setupvalue.
-- render.RenderView 在C侧是 raw 读表, 所以用 __newindex 拦截写入并替换成大RT尺寸,
-- 每次调用后清掉 raw w/h, 保证下一帧写入仍会触发 __newindex
local SS_STATE = ZCityRiceTweaks.ScopeSSState or {}
ZCityRiceTweaks.ScopeSSState = SS_STATE

local ssRT, ssW, ssH
local ssMat = CreateMaterial("zc_rice_scope_ss", "UnlitGeneric", {
    ["$basetexture"] = "vgui/white",
    ["$ignorez"] = 1
})

local function getSSRT()
    local scale = math.Clamp(CVAR_CHEAP_SS:GetInt(), 100, 200) / 100
    -- 限制在常见显卡纹理尺寸上限内
    scale = math.min(scale, 8192 / ScrW(), 8192 / ScrH())

    local w, h = math.floor(ScrW() * scale), math.floor(ScrH() * scale)

    if w ~= ssW or h ~= ssH then
        ssW, ssH = w, h
        ssRT = GetRenderTargetEx("zc_rice_scope_ss_" .. w .. "x" .. h,
            w, h,
            RT_SIZE_LITERAL,
            MATERIAL_RT_DEPTH_SEPARATE,
            bit.bor(4, 8, 256),
            0,
            IMAGE_FORMAT_RGB888
        )
        ssMat:SetTexture("$basetexture", ssRT)
    end

    return ssRT
end

local function shouldSupersample()
    return cheapReady and CVAR_CHEAP:GetBool() and CVAR_CHEAP_SS:GetInt() > 100
        and FrameNumber() - cheapFrame <= 2 and IsValid(cheapWeapon)
end

local function virtualizeViewSize(renderView)
    -- 重载或旧版本可能已挂过元表, 始终替换成当前版本
    setmetatable(renderView, {
        __newindex = function(t, k, v)
            if SS_STATE.Active and (k == "w" or k == "h") then v = SS_STATE[k] end

            rawset(t, k, v)
        end
    })
end

local function clearViewSize(renderView)
    rawset(renderView, "w", nil)
    rawset(renderView, "h", nil)
end

local function installSupersample()
    local hooks = hook.GetTable().RenderScene
    local current = hooks and hooks.jopa
    if not current then return end

    -- 重载时钩子已是我们的包装, 取回 z-city 原函数
    local original = current == ZCityRiceTweaks.SSRenderScene and ZCityRiceTweaks.OriginalRenderScene or current
    local renderView

    for i = 1, 200 do
        local name, value = debug.getupvalue(original, i)
        if not name then break end

        if name == "renderView" then
            renderView = value

            break
        end
    end

    if not istable(renderView) then return end

    virtualizeViewSize(renderView)
    clearViewSize(renderView)

    local function ssRenderScene(pos, ang, fov)
        if not shouldSupersample() then
            local rendered = original(pos, ang, fov)
            clearViewSize(renderView)

            return rendered
        end

        local rt = getSSRT()

        SS_STATE.w, SS_STATE.h = ssW, ssH
        SS_STATE.Active = true
        -- HUD 按屏幕尺寸布局, 缩回屏幕后再画
        renderView.drawhud = false

        render.PushRenderTarget(rt)
        local ok, rendered = pcall(original, pos, ang, fov)
        render.PopRenderTarget()

        SS_STATE.Active = false
        renderView.drawhud = true
        clearViewSize(renderView)

        if not ok then
            ErrorNoHalt(rendered, "\n")

            return
        end

        if not rendered then return end

        cam.Start2D()
            render.SetMaterial(ssMat)
            render.DrawScreenQuad()
        cam.End2D()

        render.RenderHUD(0, 0, ScrW(), ScrH())

        return true
    end

    ZCityRiceTweaks.OriginalRenderScene = original
    ZCityRiceTweaks.SSRenderScene = ssRenderScene
    hook.Add("RenderScene", "jopa", ssRenderScene)

    return true
end

local function doScopeModification()
    cheapReady = installCheapScope() == true

    if not installBodyHide() then
        print("[ZCityRiceTweaks] hg.renderOverride not found, own body may show in scope")
    end

    if cheapReady and not installSupersample() then
        print("[ZCityRiceTweaks] RenderScene hook not found, cheap scope supersampling disabled")
    end

    if not cheapReady then
        print("[ZCityRiceTweaks] hg.RenderWeapons not found, cheap scope disabled")
    end

    local base = weapons.GetStored("homigrad_base")
    if not base then return end

    -- 存全局, 防止文件重载时把上一次的 NewDoRT 当成原版
    local previous = base.DoRT

    ZCityRiceTweaks.OriginalDoRT = ZCityRiceTweaks.OriginalDoRT or previous
    OriginalDoRT = ZCityRiceTweaks.OriginalDoRT
    base.DoRT = NewDoRT

    -- 已存在的武器实例保存的是旧函数引用
    for _, ent in ents.Iterator() do
        if ent.DoRT == OriginalDoRT or ent.DoRT == previous then ent.DoRT = NewDoRT end
    end
end

if ZCITY_INITALIZED then
    doScopeModification()
end

hook.Add("ZCityRiceTweaksInit", "ZCityRiceTweaks_Init_OpticScope", doScopeModification)

concommand.Add("zc_rice_scope_reset_cache", function()
    lensCache = {}
    lensMissTime = {}
end)
