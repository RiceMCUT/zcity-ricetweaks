if SERVER then return end

RiceLib.Languages.AddPhrases("schinese", {
    ["zcity.ricetweaks.mute_player"] = "静音玩家",
    ["zcity.ricetweaks.unmute_player"] = "取消静音",

    ["zcity.ricetweaks.homicide.name"] = "凶杀现场",

    ["zcity.ricetweaks.homicide.select_role"] = "选择杀手职业",

    ["zcity.ricetweaks.homicide.end_menu.title"] = "回合总结",
    ["zcity.ricetweaks.homicide.end_menu.traitor"] = "杀手",
    ["zcity.ricetweaks.homicide.end_menu.gunner"] = "持枪平民",
    ["zcity.ricetweaks.homicide.end_menu.innocent"] = "平民",

    ["zcity.ricetweaks.homicide.end_menu.dead"] = "死亡",
    ["zcity.ricetweaks.homicide.end_menu.incapacitated"] = "失去行动能力",

    ["zcity.ricetweaks.homicide.type_names.standard"] = "标准",
    ["zcity.ricetweaks.homicide.type_names.soe"] = "紧急状态",
    ["zcity.ricetweaks.homicide.type_names.wildwest"] = "狂野西部",
    ["zcity.ricetweaks.homicide.type_names.gunfreezone"] = "禁枪区",
    ["zcity.ricetweaks.homicide.type_names.suicidelunatic"] = "自杀狂徒",
    ["zcity.ricetweaks.homicide.type_names.supermario"] = "超级马里奥",

    -- ===== TypeObjectives =====
    -- soe
    ["zcity.ricetweaks.homicide.type_objectives.soe.traitor.objective"] = "你口袋中藏有各种物品、毒药、炸药和武器。杀死在场的所有人。",
    ["zcity.ricetweaks.homicide.type_objectives.soe.traitor.name"] = "杀手",
    ["zcity.ricetweaks.homicide.type_objectives.soe.gunner.objective"] = "你是一名持有狩猎武器的无辜者。在事态恶化之前找出并消灭杀手。",
    ["zcity.ricetweaks.homicide.type_objectives.soe.gunner.name"] = "无辜者",
    ["zcity.ricetweaks.homicide.type_objectives.soe.innocent.objective"] = "你是一名无辜者，只能依靠自己，但可以与人群待在一起让杀手更难下手。",
    ["zcity.ricetweaks.homicide.type_objectives.soe.innocent.name"] = "无辜者",

    -- standard
    ["zcity.ricetweaks.homicide.type_objectives.standard.traitor.objective"] = "你口袋中藏有各种物品、毒药、炸药和武器。杀死在场的所有人。",
    ["zcity.ricetweaks.homicide.type_objectives.standard.traitor.name"] = "杀手",
    ["zcity.ricetweaks.homicide.type_objectives.standard.gunner.objective"] = "你是一名携带隐藏枪支的平民。你已决定帮助警方更快找到罪犯。",
    ["zcity.ricetweaks.homicide.type_objectives.standard.gunner.name"] = "平民",
    ["zcity.ricetweaks.homicide.type_objectives.standard.innocent.objective"] = "你是一场谋杀现场的平民，虽然被杀的不是你，但你最好保持警惕。",
    ["zcity.ricetweaks.homicide.type_objectives.standard.innocent.name"] = "平民",

    -- wildwest
    ["zcity.ricetweaks.homicide.type_objectives.wildwest.traitor.objective"] = "这座小镇容不下我们所有人。",
    ["zcity.ricetweaks.homicide.type_objectives.wildwest.traitor.name"] = "杀手",
    ["zcity.ricetweaks.homicide.type_objectives.wildwest.gunner.objective"] = "你是这个镇上的警长。你得找到并干掉那个无法无天的混蛋。",
    ["zcity.ricetweaks.homicide.type_objectives.wildwest.gunner.name"] = "警长",
    ["zcity.ricetweaks.homicide.type_objectives.wildwest.innocent.objective"] = "我们得伸张正义，有个无法无天的混蛋在杀人。",
    ["zcity.ricetweaks.homicide.type_objectives.wildwest.innocent.name"] = "牛仔同伴",

    -- gunfreezone
    ["zcity.ricetweaks.homicide.type_objectives.gunfreezone.traitor.objective"] = "你口袋中藏有各种物品、毒药、炸药和武器。杀死在场的所有人。",
    ["zcity.ricetweaks.homicide.type_objectives.gunfreezone.traitor.name"] = "杀手",
    ["zcity.ricetweaks.homicide.type_objectives.gunfreezone.gunner.objective"] = "你是一场谋杀现场的平民，虽然被杀的不是你，但你最好保持警惕。",
    ["zcity.ricetweaks.homicide.type_objectives.gunfreezone.gunner.name"] = "平民",
    ["zcity.ricetweaks.homicide.type_objectives.gunfreezone.innocent.objective"] = "你是一场谋杀现场的平民，虽然被杀的不是你，但你最好保持警惕。",
    ["zcity.ricetweaks.homicide.type_objectives.gunfreezone.innocent.name"] = "平民",

    -- suicidelunatic
    ["zcity.ricetweaks.homicide.type_objectives.suicidelunatic.traitor.objective"] = "我的兄弟，真主保佑，别让他失望。",

    ["zcity.ricetweaks.homicide.type_objectives.suicidelunatic.traitor.name"] = "烈士",
    ["zcity.ricetweaks.homicide.type_objectives.suicidelunatic.gunner.objective"] = "那个疯子发狂了，现在你得活下来。",
    ["zcity.ricetweaks.homicide.type_objectives.suicidelunatic.gunner.name"] = "无辜者",
    ["zcity.ricetweaks.homicide.type_objectives.suicidelunatic.innocent.objective"] = "那个疯子发狂了，现在你得活下来。",
    ["zcity.ricetweaks.homicide.type_objectives.suicidelunatic.innocent.name"] = "无辜者",

    -- supermario
    ["zcity.ricetweaks.homicide.type_objectives.supermario.traitor.objective"] = "你是邪恶的马里奥！四处跳跃，击倒所有人。",
    ["zcity.ricetweaks.homicide.type_objectives.supermario.traitor.name"] = "杀手马里奥",
    ["zcity.ricetweaks.homicide.type_objectives.supermario.gunner.objective"] = "你是英雄马里奥！用你的跳跃能力阻止杀手。",
    ["zcity.ricetweaks.homicide.type_objectives.supermario.gunner.name"] = "英雄马里奥",
    ["zcity.ricetweaks.homicide.type_objectives.supermario.innocent.objective"] = "你是平民马里奥，活下去并避开杀手的陷阱！",
    ["zcity.ricetweaks.homicide.type_objectives.supermario.innocent.name"] = "无辜者马里奥",

    -- ===== SubRoles =====
    ["zcity.ricetweaks.homicide.subrole.traitor_default.name"] = "Defoko",
    ["zcity.ricetweaks.homicide.subrole.traitor_default.description"] = [[默认角色。
你为此准备了很久。
你装备了各种武器、毒药、炸药、手榴弹，还有一把折叠刀具和带额外弹匣的消音手枪来助你杀戮。]],
    ["zcity.ricetweaks.homicide.subrole.traitor_default.objective"] = "你口袋中藏有各种物品、毒药、炸药和武器。杀死在场的所有人。",

    ["zcity.ricetweaks.homicide.subrole.traitor_default_soe.name"] = "Defoko",
    ["zcity.ricetweaks.homicide.subrole.traitor_default_soe.description"] = [[默认角色。
你为这一刻准备了很久。
你装备了各种武器、毒药、炸药、手榴弹，还有一把重型刀和带额外弹匣的催眠手枪来助你杀戮。]],
    ["zcity.ricetweaks.homicide.subrole.traitor_default_soe.objective"] = "你口袋中藏有各种物品、毒药、炸药和武器。杀死在场的所有人。",

    ["zcity.ricetweaks.homicide.subrole.traitor_infiltrator.name"] = "渗透者",
    ["zcity.ricetweaks.homicide.subrole.traitor_infiltrator.description"] = [[可以从背后扭断别人的脖子。
可以在其他玩家处于布娃娃状态时完全伪装成他们。
除了刀、肾上腺素和烟雾弹外没有其他武器或工具。
适合喜欢智斗的玩家。]],
    ["zcity.ricetweaks.homicide.subrole.traitor_infiltrator.objective"] = "你是转移注意力的专家。保持隐蔽，逐个击杀。",

    ["zcity.ricetweaks.homicide.subrole.traitor_infiltrator_soe.name"] = "渗透者",
    ["zcity.ricetweaks.homicide.subrole.traitor_infiltrator_soe.description"] = [[可以从背后扭断别人的脖子。
可以在其他玩家处于布娃娃状态时完全伪装成他们。
拥有烟雾弹、对讲机、刀、带2个额外射击头的电击枪和肾上腺素。
适合喜欢智斗的玩家。]],
    ["zcity.ricetweaks.homicide.subrole.traitor_infiltrator_soe.objective"] = "你是转移注意力的专家。保持隐蔽，逐个击杀。",

    ["zcity.ricetweaks.homicide.subrole.traitor_assasin.name"] = "刺客",
    ["zcity.ricetweaks.homicide.subrole.traitor_assasin.description"] = [[可以从任何角度快速缴械他人。
从背后缴械更快。
若目标处于布娃娃状态，从正面缴械也更快。
精通枪械射击。
拥有额外耐力（比其他杀手多80单位）。
配备对讲机。
适合喜欢智斗的玩家。]],
    ["zcity.ricetweaks.homicide.subrole.traitor_assasin.objective"] = "你是枪械和缴械的专家。缴械枪手并用他的武器对付其他人。",

    ["zcity.ricetweaks.homicide.subrole.traitor_assasin_soe.name"] = "刺客",
    ["zcity.ricetweaks.homicide.subrole.traitor_assasin_soe.description"] = [[可以从任何角度快速缴械他人。
从背后缴械更快。
若目标处于布娃娃状态，从正面缴械也更快。
精通枪械射击。
拥有额外耐力（比其他杀手多80单位）。
配备对讲机、刀、肾上腺素和手电筒。
适合喜欢智斗的玩家。]],
    ["zcity.ricetweaks.homicide.subrole.traitor_assasin_soe.objective"] = "你是枪械和缴械的专家。缴械枪手并用他的武器对付其他人。",

    ["zcity.ricetweaks.homicide.subrole.traitor_chemist.name"] = "化学家",
    ["zcity.ricetweaks.homicide.subrole.traitor_chemist.description"] = [[拥有多种化学试剂、肾上腺素和刀。
对上述所有化学试剂有一定程度的抗性。
可以检测空气中化学试剂的存在和浓度。]],
    ["zcity.ricetweaks.homicide.subrole.traitor_chemist.objective"] = "你是一个决定用知识伤害他人的化学家。毒害一切。",

    ["zcity.ricetweaks.homicide.subrole.traitor_zombie.name"] = "僵尸",
    ["zcity.ricetweaks.homicide.subrole.traitor_zombie.description"] = [[可以悄无声息地感染其他玩家。
被感染的玩家可以被医生治愈。
如果所有玩家都被治愈，僵尸将失败。
死亡时会随机转移到另一个被感染玩家的身体中。
没有任何武器或工具。
虽然是僵尸，但仍保持正常人类的外观。]],
    ["zcity.ricetweaks.homicide.subrole.traitor_zombie.objective"] = "你是僵尸。感染所有人来获胜。避开医生。",

    -- ===== Professions =====
    ["zcity.ricetweaks.homicide.profession.doctor.name"] = "医生",
    ["zcity.ricetweaks.homicide.profession.huntsman.name"] = "猎人",
    ["zcity.ricetweaks.homicide.profession.engineer.name"] = "工程师",
    ["zcity.ricetweaks.homicide.profession.cook.name"] = "厨师",
    ["zcity.ricetweaks.homicide.profession.builder.name"] = "建筑工",

    -- ===== Roles: standard =====
    ["zcity.ricetweaks.homicide.role.standard.traitor.name"] = "杀手",
    ["zcity.ricetweaks.homicide.role.standard.traitor.objective"] = "你为此准备了很久。杀死所有人。",
    ["zcity.ricetweaks.homicide.role.standard.gunner.name"] = "持枪平民",
    ["zcity.ricetweaks.homicide.role.standard.innocent.name"] = "平民",

    -- ===== Roles: soe =====
    ["zcity.ricetweaks.homicide.role.soe.traitor.name"] = "杀手",
    ["zcity.ricetweaks.homicide.role.soe.gunner.name"] = "持枪平民",
    ["zcity.ricetweaks.homicide.role.soe.innocent.name"] = "平民",

    -- ===== Roles: wildwest =====
    ["zcity.ricetweaks.homicide.role.wildwest.traitor.name"] = "杀手",
    ["zcity.ricetweaks.homicide.role.wildwest.traitor.objective"] = "你为此准备了很久。杀死所有人。",
    ["zcity.ricetweaks.homicide.role.wildwest.gunner.name"] = "持枪平民",
    ["zcity.ricetweaks.homicide.role.wildwest.innocent.name"] = "平民",

    -- ===== Roles: gunfreezone =====
    ["zcity.ricetweaks.homicide.role.gunfreezone.traitor.name"] = "杀手",
    ["zcity.ricetweaks.homicide.role.gunfreezone.gunner.name"] = "持枪平民",
    ["zcity.ricetweaks.homicide.role.gunfreezone.innocent.name"] = "平民",

    -- ===== Roles: supermario =====
    ["zcity.ricetweaks.homicide.role.supermario.traitor.name"] = "杀手马里奥",
    ["zcity.ricetweaks.homicide.role.supermario.traitor.objective"] = "你是邪恶的马里奥！四处跳跃，击倒所有人。",
    ["zcity.ricetweaks.homicide.role.supermario.gunner.name"] = "英雄马里奥",
    ["zcity.ricetweaks.homicide.role.supermario.gunner.objective"] = "你是英雄马里奥！用你的跳跃能力阻止杀手。",
    ["zcity.ricetweaks.homicide.role.supermario.innocent.name"] = "无辜者马里奥",
    ["zcity.ricetweaks.homicide.role.supermario.innocent.objective"] = "你是平民马里奥，活下去并避开杀手的陷阱！",
})
