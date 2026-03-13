local L = LibStub("AceLocale-3.0"):NewLocale("Dumpster", "ruRU", true)

if L then
-- Translator ZamestoTV
L["startupmsg"]	= function(X) return "Dumpster версия "..X.." загружена (/dumpster)"; end
L["usage"] = "/dumpster -- отображает это сообщение\
\
 Используйте \"/dumpster extrahelp\" для примеров и дополнительной информации."

L["extrahelp"] = "/din [квалификаторы] предметы - перемещает предметы в ваш банк/гильдейский банк\
/dout [квалификаторы] предметы - выгружает предметы из вашего банка/текущей вкладки гильдейского банка (в ваш инвентарь)\
\
'предметы' могут быть частичным названием, например, \"рецепт\" или \"Чемпиона\" (без кавычек).\
Чтобы выбрать все, используйте точку.\
\
'предметы' также могут быть названием набора.\
\
Квалификаторы могут быть:\
- количество стопок (/dout 5 felweed)\
- цвета: /gray /white /green /blue /purple /orange /red\
          /poor /common /uncommon /rare /epic /legendary /artifact\
- привязка: /boa /boe /bop /bou /bound /notbound\
        /account /equip /pickup /use /soulbound\
       /warbound /wb/ btw\
- дополнение: /classic /tbc /wotlk /cata /mop /wod /legion /bfa\
- поиск по подсказке (/dout /t \"сделано Бобом\" тигр)\
- /to [персонаж], автоматически заполняет поле Кому: при отправке почты\
- /remain [число], перемещает все, кроме указанного количества предметов\
- /only [число], перемещает до указанного количества предметов\
- /full или /partial, перемещает только полные/частичные стопки\
\
Примеры:\
\"/dout 3 /epic /boe тигр\" - выгружает 3 эпических предмета с привязкой при экипировке, содержащих 'тигр' в названии\
\"/din /green /soulbound .\" - перемещает все необычные предметы с привязкой к душе в ваш банк\
\"/din /green /to \"Mrdisenchant-Draka\" /boe /legion .\" - отправляет все необычные предметы дополнения Legion с привязкой при экипировке на Mrdisenchant-Draka\
\"/din /to MisterTailor /full cloth .\" - отправляет все полные стопки ткани на MisterTailor"

L["nothingtodump"]	= "Вы не указали, какие предметы перемещать"
L["notsafein"]		= "Нет открытых окон банка, почты, торговца или обмена, не безопасно перемещать внутрь!"
L["notsafeout"]		= "Нет открытых окон банка, не безопасно выгружать!"
L["notsafeonly"]	= "/only нельзя использовать здесь"
L["novendor"]		= "Не удается найти опцию покупки/продажи! Это торговец?"
L["notsafe"]		= "Не перемещаю, так как это не безопасно"
L["battlepet"]		= "Поиск по подсказке не работает с питомцами или игрушками"
L["invalidparam"]	= function(X) return "Недопустимый параметр ["..X.."], отмена"; end
L["AllExist"]		= function(D,X,Y,Z) return D.." предметов перемещено|r для "..X.."|r ("..Y.." запрошено, "..Z.." уже существуют)";end
L["totaldumped"]	= function(X,Y,Z) return X.." предметов перемещено|r для "..Y.."|r ("..Z.." запрошено)" end
L["DumpMerchantTooSmall"]	= function(X,Y) return "Количество оставшихся предметов для покупки ("..X..") меньше минимального покупаемого количества ("..Y.."). Покупка прекращена."; end
L["dumpsetlist"]	= function(X) return "Количество наборов: "..X; end
L["dumpsetinvalid"]	= function(X) return "Недопустимое название набора ["..X.."]"; end
L["dumpsetdeleted"]	= function(X) return "Удален набор ["..X.."]"; end
L["dumpsetempty"]	= function(X) return "Пустой набор указан для ["..X.."]"; end
L["dumpsetadded"]	= function(X,Y) return "Добавлен набор с названием ["..X.."], содержащий ["..Y.."]"; end
L["dumpsetuse"]	= function(X,Y) return "Используется набор с названием ["..X.."], содержащий ["..Y.."]"; end

L["warbound"]    = ITEM_ACCOUNTBOUND;
L["bindBOA"]    = ITEM_ACCOUNTBOUND;
L["bindBOE"]    = ITEM_BIND_ON_EQUIP;
L["bindBOU"]    = ITEM_BIND_ON_USE;
L["bindBOP"]    = ITEM_SOULBOUND;
L["bindAll"]    = "Все привязки";
L["bindBound"]  = ITEM_SOULBOUND;
L["notbound"]   = "не привязано к душе";

L["AllExp"]       = "Все дополнения";
L["classic"]      = "Classic";
L["tbc"]          = "The Burning Crusade";
L["wotlk"]        = "Wrath of the Lich King";
L["cata"]         = "Cataclysm";
L["mop"]          = "Mists of Pandaria";
L["wod"]          = "Warlords of Draenor";
L["legion"]       = "Legion";
L["bfa"]          = "Battle for Azeroth";
L["sl"]           = "Shadowlands";
L["df"]           = "Dragonflight";
L["tww"]          = "The War Within";
L["midnight"]     = "Midnight";
L["thelasttitan"] = "The Last Titan";

local debugtext = "|cff7f0000 ОТЛАДКА |r"

L["debugDumpIt"]                   = function(C,W,X,Y,Z) return debugtext.."Перемещение с параметрами maxcount=["..C.."], дополнение=["..W.."], привязка=["..X.."], направление=["..Y.."], поиск=["..Z.."]"; end
L["debugSuperEnabled"]             = debugtext.."Суперотладочные сообщения включены -- готовьтесь к спаму!";
L["debugSuperDisabled"]            = debugtext.."Суперотладочные сообщения отключены";
L["debugEnabled"]                  = debugtext.."Отладочные сообщения включены";
L["debugDisabled"]                 = debugtext.."Отладочные сообщения отключены";
L["debugnumstacks12"]              = debugtext.."Установка numstacks на 12, так как мы у почтового ящика";
L["debugnumstacks6"]               = debugtext.."Установка numstacks на 6, так как мы в окне обмена";
L["debugnumstacks"]                = function(X) return debugtext.."Установка numstacks на ["..X.."] по запросу"; end
L["debugDumpBag"]                  = function(W,X,Y,Z) return debugtext.."Проверка ["..W.."] сумки ["..X.."] с ["..Y.."] слотами для ["..Z.."]"; end
L["debugDumpMail"]                 = function(X) return debugtext.."Проверка почты для ["..X.."]"; end
L["debugDumpMerchant"]             = function(X) return debugtext.."Покупка ["..X.."] у торговца"; end
L["debugDumpBagCheckItem"]         = function(X,Y,Z) return debugtext.."Проверка предмета ["..X.."] в сумке ["..Y.."] слот ["..Z.."]"; end
L["debugDumpBagDumpItem"]          = function(X,Y) return debugtext.."Перемещение предмета ["..X.."], maxcount= "..Y; end
L["debugDumpBagMax"]               = function(X) return debugtext.."Не перемещаю предмет ["..X.."], так как maxcount=0"; end
L["debugNumBankBags"]              = function(X) return debugtext.."Найдено банковских сумок: ["..X.."]"; end
L["debugSearch"]                   = function(X) return debugtext.."Текущие условия поиска: ["..X.."]"; end
L["debugParseResults"]             = function(X,Y,Z) return debugtext.."Результат ParseOptions: ["..X.."]=["..Y.."]"; end
L["debugTooltip"]                  = function(X) return debugtext.."Подсказка предмета = ["..X.."]"; end
L["debugExpansion"]                = function(X) return debugtext.."Дополнение предмета = ["..X.."]"; end
L["debugTooltipBindFail"]          = function(X,Y) return debugtext.."Не удалось найти статус привязки ["..X.."], искал текст ["..Y.."]"; end
L["debugTooltipExpansionFail"]     = function(X,Y) return debugtext.."Не удалось найти дополнение ["..X.."], искал текст ["..Y.."]"; end
L["debugTooltipFail"]              = function(X) return debugtext.."Не удалось найти текст в подсказке, искал текст ["..X.."]"; end
L["debugatMailSend"]               = debugtext.."SendMailFrame видно, значит мы на странице отправки почты";
L["debugatMailInbox"]              = debugtext.."InboxPrevPageButton видно, значит мы во входящих";
L["debugatMailboxflag"]            = debugtext.."Флаг MAIL_SHOW установлен, значит мы у почтового ящика";
L["debugatBank"]                   = debugtext.."BankFrame видно, значит мы в банке";
L["debugatBankflag"]               = debugtext.."Флаг BANKFRAME_OPENED установлен, значит мы в банке";
L["debugatGuildBank"]              = debugtext.."GuildBankFrame видно, значит мы в гильдейском банке";
L["debugatGuildBankflag"]          = debugtext.."Флаг GUILDBANKFRAME_OPENED установлен, значит мы в гильдейском банке";
L["debugatAccountBank"]            = debugtext.."AccountBankPanel видно, значит мы в банке Warband";
L["debugatGuildBankflag"]          = debugtext.."Флаг BANKFRAME_OPENED установлен и AccountBankPanel видно, значит мы в банке Warband";
L["debugatMerchant"]               = debugtext.."MerchantFrame видно, значит мы у торговца";
L["debugatMerchantflag"]           = debugtext.."Флаг MERCHANT_SHOW установлен, значит мы у торговца";
L["debugatTrade"]                  = debugtext.."TradeFrame видно, значит мы в окне обмена";
L["debugatTradeflag"]              = debugtext.."Флаг MERCHANT_SHOW установлен, значит мы у торговца";
L["debugatGossip"]                 = debugtext.."GossipFrame видно, значит мы разговариваем с NPC";
L["debugatGossipflag"]             = debugtext.."Флаг GOSSIP_SHOW установлен, значит мы разговариваем с NPC";
L["debugevent"]                    = function(X) return debugtext.."Событие "..X.." сработало"; end
L["debugDelayed"]                  = function(X,Y) return debugtext.."Отложенное перемещение ["..X.."], направление: ["..Y.."]"; end
L["debugGossipOption"]             = function(X) return debugtext.."Найдена опция диалога с торговцем: ["..X.."]"; end
L["debugleftovers"]                = function(X) return debugtext.."Сохранение остатков: ["..X.."]"; end
L["debugNoStackFull"]              = debugtext.."Нет квалификаторов полной или частичной стопки, пропускаю";
L["debugInvalidStackFull"]         = function(X) return debugtext.."so[stackfull] недопустим: ["..X.."]"; end
L["debugStackFullcheckmatch"]      = function(X,Y) return debugtext.."Полная стопка: ["..X.."], у нас ["..Y.."]"; end
L["debugDumpMerchantQuantity"]     = function(X,Y) return debugtext.."Предмет ["..X.."] имеет количество ["..Y.."]"; end
L["debugDumpMerchantMaxStack"]     = function(X) return debugtext.."Установка buycount на ["..X.."] из-за GetMerchantItemMaxStack"; end
L["debugTooltipFailed"]            = function(X,Y,Z) return debugtext.."Установка подсказки с ["..X.."], сумка ["..Y.."] слот ["..Z.."] не удалась, откат к общей подсказке предмета"; end
L["debugProcessDelayed"]           = function(X,Y) return debugtext.."ProcessDelayed сработал ["..X.."], поиск = ["..Y.."]"; end
L["debugGbankDelayed"]             = debugtext.."Обработка отложенного запроса гильдейского банка"
L["debugGbankFirst"]               = debugtext.."Обработка первого запроса гильдейского банка"
L["debugExistingCount"]            = function(X) return debugtext.."Существующее количество: ["..X.."]"; end
L["debugnoitem"]                   = function(X,Y,Z) return debugtext.."Пустой слот в "..X..", сумка "..Y..", слот "..Z; end
L["debugfoundflag"]                = function(X) return debugtext.."Найден флаг: ["..X.."]"; end
L["debugflagtoken"]                = function(X) return debugtext.."Текущий токен флага: ["..X.."]"; end

end
