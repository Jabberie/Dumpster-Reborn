local L = LibStub("AceLocale-3.0"):NewLocale("Dumpster", "enUS", true)

if L then

L["startupmsg"]	= function(X) return "Dumpster version "..X.." loaded (/dumpster)"; end
L["usage"] = "/dumpster -- displays this message\
\
 Use \"/dumpster extrahelp\" for examples and more info."

L["extrahelp"] = "/din [qualifiers] stuff - dumps stuff in to your bank/guild bank\
/dout [qualifiers] stuff - dumps stuff out of your bank/current guild bank tab (and into your inventory)\
\
'stuff' can be a partial name like \"recipe\" or \"of the Champion\" (without quotes).\
To match everything, use a period.\
\
'stuff' can also be a set name.\
\
Qualifiers can be:\
- number of stacks (/dout 5 felweed)\
- colors: /gray /white /green /blue /purple /orange /red\
          /poor /common /uncommon /rare /epic /legendary /artifact\
- bind: /boa /boe /bop /bou /bound /notbound\
        /account /equip /pickup /use /soulbound\
- tooltip search (/dout /t \"made by bob\" tiger)\
- /to [person], will automatically fill the To: field when mailing\
- /remain [number], will move all but [number] items\
- /only [number], will move up to [number] items\
- /full or /partial, will only move full/partial stacks\
\
Examples:\
\"/dout 3 /epic /boe tiger\" - dumps out 3 epic BOE items with 'tiger' in the name\
\"/din /green /soulbound .\" - dumps all uncommon soulbound items into your bank\
\"/din /to MisterTailor /full cloth .\" - mails all your full stacks of cloth to MisterTailor"

L["nothingtodump"]	= "You didn't tell me what stuff to dump"
L["notsafein"]		= "No bank, mail, merchant, or trade frames visible, not safe to dump in!"
L["notsafeout"]		= "No bank frames visible, not safe to dump out!"
L["notsafeonly"]	= "/only can't be used here"
L["novendor"]		= "Can't find the buy/sell option! Is this a merchant?"
L["notsafe"]		= "Not dumping because it's not safe"
L["invalidparam"]	= function(X) return "Invalid parameter ["..X.."], cancelling"; end
L["AllExist"]		= function(D,X,Y,Z) return D.." items dumped|r for "..X.."|r ("..Y.." requested, "..Z.." already exist)";end
L["totaldumped"]	= function(X,Y,Z) return X.." items dumped|r for "..Y.."|r ("..Z.." requested)" end
L["DumpMerchantTooSmall"]	= function(X,Y) return "The number of items left to buy ("..X..") is less than the minimum purchaseable amount ("..Y..").  Not buying any more."; end
L["dumpsetlist"]	= function(X) return "Number of sets: "..X; end
L["dumpsetinvalid"]	= function(X) return "Invalid set name ["..X.."]"; end
L["dumpsetdeleted"]	= function(X) return "Deleted set ["..X.."]"; end
L["dumpsetempty"]	= function(X) return "Empty set given for ["..X.."]"; end
L["dumpsetadded"]	= function(X,Y) return "Added set named ["..X.."] containing ["..Y.."]"; end
L["dumpsetuse"]	= function(X,Y) return "Using set named ["..X.."] containing ["..Y.."]"; end


L["bindBOA"]	= "Binds to account";		-- matches in-game text
L["bindBOE"]	= ITEM_BIND_ON_EQUIP ;		-- matches in-game text
L["bindBOU"]	= ITEM_BIND_ON_USE ;		-- matches in-game text
L["bindBOP"]	= ITEM_BIND_ON_PICKUP ;		-- matches in-game text
L["bindAll"]	= "All bindings";		-- doesn't match anything in-game
L["bindBound"]	= ITEM_SOULBOUND ;		-- matches in-game text
L["notbound"]	= "not Soulbound";		-- doesn't match anything in-game

local debugtext = "|cff7f0000 DEBUG |r"

L["debugDumpIt"]	= function(C,X,Y,Z) return debugtext.."Dumping with parameters maxcount=["..C.."], bind=["..X.."], inorout=["..Y.."], search=["..Z.."]"; end

L["debugSuperEnabled"]	= debugtext.."Super debugging messages enabled -- bring on the spam!";
L["debugSuperDisabled"]	= debugtext.."Super debugging messages disabled";
L["debugEnabled"]	= debugtext.."Debugging messages enabled";
L["debugDisabled"]	= debugtext.."Debugging messages disabled";
L["debugnumstacks12"]	= debugtext.."Setting numstacks to 12 since we're at the mailbox"
L["debugnumstacks6"]	= debugtext.."Setting numstacks to 6 since we're at the trade frame"
L["debugnumstacks"]	= function(X) return debugtext.."Setting numstacks to ["..X.."] as requested"; end
L["debugDumpBag"]	= function(W,X,Y,Z) return debugtext.."Checking ["..W.."] bag ["..X.."] with ["..Y.."] slots for ["..Z.."]"; end
L["debugDumpMail"]	= function(X) return debugtext.."Checking mail for ["..X.."]"; end
L["debugDumpMerchant"]	= function(X) return debugtext.."Buying ["..X.."] from merchant"; end
L["debugDumpBagCheckItem"]	= function(X,Y,Z) return debugtext.."Checking item ["..X.."] in bag ["..Y.."] slot ["..Z.."]"; end
L["debugDumpBagDumpItem"]	= function(X,Y) return debugtext.."Dumping item ["..X.."], maxcount= "..Y; end
L["debugDumpBagMax"]	= function(X) return debugtext.."Not dumping item ["..X.."], because maxcount=0"; end
L["debugNumBankBags"]	= function(X) return debugtext.."Bank bags found: ["..X.."]"; end
L["debugSearch"]	= function(X) return debugtext.."Current search terms: ["..X.."]"; end

L["debugParseResults"]	= function(X,Y,Z) return debugtext.."ParseOptions result: ["..X.."]=["..Y.."]"; end
L["debugTooltip"]	= function(X) return debugtext.."Item tooltip = ["..X.."]"; end
L["debugTooltipBindFail"]	= function(X,Y) return debugtext.."Failed to find bind status ["..X.."], looked for text ["..Y.."]"; end
L["debugTooltipFail"]	= function(X) return debugtext.."Failed to find text in tooltip, looked for text ["..X.."]"; end

L["debugatMailSend"]	= debugtext.."SendMailFrame is visible, therefore we're at the mail send page";
L["debugatMailInbox"]	= debugtext.."InboxPrevPageButton is visible, therefore we're at the inbox";
L["debugatMailboxflag"]	= debugtext.."MAIL_SHOW flagged, therefore we're at the mailbox";
L["debugatBank"]	= debugtext.."BankFrame is visible, therefore we're at the bank";
L["debugatBankflag"]	= debugtext.."BANKFRAME_OPENED flagged, therefore we're at the bank";
L["debugatGuildBank"]	= debugtext.."GuildBankFrame is visible, therefore we're at the guild bank";
L["debugatGuildBankflag"]	= debugtext.."GUILDBANKFRAME_OPENED flagged, therefore we're at the guild bank";
L["debugatMerchant"]	= debugtext.."MerchantFrame is visible, therefore we're at a vendor";
L["debugatMerchantflag"]	= debugtext.."MERCHANT_SHOW flagged, therefore we're at a vendor";
L["debugatTrade"]	= debugtext.."TradeFrame is visible, therefore we're trading";
L["debugatTradeflag"]	= debugtext.."MERCHANT_SHOW flagged, therefore we're at a vendor";
L["debugatGossip"]	= debugtext.."GossipFrame is visible, therefore we're talking to an NPC";
L["debugatGossipflag"]	= debugtext.."GOSSIP_SHOW flagged, therefore we're talking to an NPC";
L["debugevent"]		= function(X) return debugtext..X.." event fired"; end
L["debugDelayed"]	= function(X,Y) return debugtext.."Delaying dump of ["..X.."], direction: ["..Y.."]"; end
L["debugGossipOption"]	= function(X) return debugtext.."Found vendor gossip option: ["..X.."]"; end
L["debugleftovers"]	= function(X) return debugtext.."Saving leftovers: ["..X.."]"; end
L["debugNoStackFull"]	= debugtext.."No full or partial stack qualifiers, so passing";
L["debugInvalidStackFull"]	= function(x) return debugtext.."so[stackfull] is invalid: ["..X.."]"; end
L["debugStackFullcheckmatch"]	= function(X,Y) return debugtext.."Full stack is ["..X.."], we have ["..Y.."]"; end
L["debugDumpMerchantQuantity"]	= function(X,Y) return debugtext.."Item ["..X.."] has quantity ["..Y.."]"; end
L["debugDumpMerchantMaxStack"]	= function(X) return debugtext.."Setting buycount to ["..X.."] due to GetMerchantItemMaxStack"; end
L["debugTooltipFailed"]	= function(X,Y,Z) return debugtext.."Setting tooltip with ["..X.."], bag ["..Y.."] slot ["..Z.."] failed, falling back to generic item tooltip"; end
L["debugProcessDelayed"]	= function(X,Y) return debugtext.."ProcessDelayed triggered ["..X.."], search = ["..Y.."]"; end
L["debugGbankDelayed"]	= debugtext.."Processing delayed guild bank request"
L["debugGbankFirst"]	= debugtext.."Processing first guild bank request"
L["debugExistingCount"]	= function(X) return debugtext.."Existing count: ["..X.."]"; end
L["debugnoitem"]	= function(X,Y,Z) return debugtext.."Empty slot in "..X..", bag "..Y..", slot "..Z; end
L["debugfoundflag"]	= function(X) return debugtext.."Found flag: ["..X.."]"; end
L["debugflagtoken"]	= function(X) return debugtext.."Current flag token: ["..X.."]"; end

end
