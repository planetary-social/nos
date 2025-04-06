#!/usr/bin/env python3
import json
import os
import tempfile
import shutil

# Path to the Localizable.xcstrings file
file_path = '/Users/rabble/code/verse/nos/Nos/Assets/Localization/Localizable.xcstrings'

# Create a backup of the original file
backup_file = file_path + '.zh-Hant.bak'
shutil.copy2(file_path, backup_file)
print(f"Created backup at {backup_file}")

# Load the translations file (since we'll be modifying it, we need to load it completely)
with open(file_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Define Traditional Chinese translations here
trad_chinese_translations = {
  "acceptTermsAndPrivacy": "繼續即表示我接受[服務條款](https://nos.social/terms-of-service)和[隱私政策](https://nos.social/privacy)",
  "accountPartialSuccessDescription": "應用無法保存您選擇的顯示名稱或用戶名。您可以稍後在個人資料中設置它們。",
  "accountPartialSuccessHeadline": "您已設置好帳戶，但是...",
  "accountSuccessDescription": "現在您已經知道自己在Nostr上的身份，讓我們找其他人關注吧！",
  "accountSuccessHeadline": "您已成功設置帳戶！",
  "addListsDescription": "將列表添加到您的信息流以按主題過濾。",
  "ageVerificationDescription": "出於法律原因，我們必須確保您年滿此年齡才能使用Nos。",
  "ageVerificationHeadline": "您是否超過16歲？",
  "alreadyHaveANIP05": "不，謝謝。我已經有NIP-05了",
  "anyRelaysSupportingNIP40": "您的中繼服務器都不支持過期消息。請添加一個並重試。",
  "anErrorOccurred": "發生了錯誤。",
  "bioPlaceholder": "告訴我們一些關於您的信息...",
  "buildYourNetworkDescription": "當您關注他人時，Nostr會變得更好。讓我們填充您的信息流吧！",
  "buildYourNetworkHeadline": "建立您的網絡",
  "cantSaveYourUsername": "無法保存您的用戶名",
  "chooseNIP05Provider": "選擇NIP-05提供商",
  "chooseStrongKeyphrase": "選擇一個強密碼短語",
  "clickToViewSensitiveContent": "點擊查看敏感內容",
  "completeSetup": "完成設置",
  "confirming": "確認中...",
  "connecting": "連接中...",
  "contentHiddenWarning": "此內容已隱藏，因為它不適合所有觀眾",
  "copyFailed": "複製失敗",
  "copyKey": "複製密鑰",
  "copyNpub": "複製npub",
  "createNewKey": "創建新密鑰",
  "createPublishedBy": "創建於 %@ - 發布者 %@",
  "createANewPost": "創建新帖子",
  "defaultContentWarning": "敏感內容",
  "defaultDisplayName": "新Nostronaut",
  "defaults": "默認值",
  "deleteAccountQuestion": "刪除帳戶？",
  "deleteConfirmation": "您確定要刪除這個嗎？",
  "deleteUndoneWarning": "此操作無法撤銷。",
  "disconnected": "已斷開連接",
  "displayNamePlaceholder": "您的顯示名稱",
  "displayNamePrompt": "您希望別人如何認識您？",
  "dontHaveNpub": "沒有npub？創建一個新的！",
  "dontLoseYourKey": "不要丟失您的密鑰！",
  "editAccount": "編輯帳戶",
  "editDisplayName": "編輯顯示名稱",
  "editUsername": "編輯用戶名",
  "emptyFeed": "空信息流",
  "enterDisplayName": "輸入顯示名稱",
  "enterUsernamePlaceholder": "輸入用戶名",
  "enterYourPrivateKey": "輸入您的私鑰",
  "eventCouldNotBeDecrypted": "消息無法解密",
  "eventRemotelyDeleted": "此帖子已被作者刪除",
  "events": "事件",
  "everyone": "所有人",
  "expirationTime": "過期時間",
  "feedEmpty": "您的信息流是空的！",
  "feedEmptyDescription": "尋找人關注以填充您的信息流",
  "feedOfPeopleIFollow": "我關注的人的信息流",
  "feedsSelection": "信息流選擇",
  "filterWarning": "內容可能包含暴力、圖像或性內容",
  "findFriendsDescription": "通過直接請求他們連接來找朋友。",
  "findFriendsHeadline": "尋找朋友",
  "flagAsSpam": "標記為垃圾信息",
  "flagConfirm": "確認標記",
  "flagInappropriate": "標記為不適當",
  "flagPrompt": "為什麼要標記這篇帖子？",
  "flagReason": "標記原因",
  "flagThisAuthor": "標記這位作者",
  "flagThisPost": "標記這篇帖子",
  "followFormat": "關注 %@",
  "followingFormat": "正在關注 %@",
  "generateNew": "生成新的",
  "giftedUserSignup": "您已收到免費試用訂閱",
  "goToFeed": "前往信息流",
  "harassing": "騷擾",
  "hide": "隱藏",
  "iAcceptTheTerms": "我接受條款",
  "iAmOver16": "我已滿16歲",
  "illegal": "違法",
  "importNsec": "導入nsec",
  "importNsecDescription": "使用現有Nostr密鑰登錄",
  "inNewPost": "在新帖子中",
  "inappropriate": "不適當",
  "incorrectPrivateKey": "私鑰不正確",
  "invalidLink": "無效鏈接",
  "joined": "已加入",
  "keyPhraseHint": "這用於加密您的私鑰，所以請確保它強大且對您是唯一的。",
  "keyphraseHint": "使用您能記住的唯一密碼短語",
  "keywordSearch": "關鍵詞搜索",
  "keywordSearchPlaceholder": "搜索關鍵詞",
  "leaveAComment": "留下評論...",
  "letsGetYouSet": "讓我們為您設置！",
  "likes": "喜歡",
  "loading": "加載中...",
  "manageLists": "管理列表",
  "manageSettings": "管理設置",
  "message": "消息",
  "messagesHiddenWarning": "消息已隱藏",
  "missingLightningAddress": "缺少Lightning地址",
  "moderation": "審核",
  "myFeed": "我的信息流",
  "name": "名稱",
  "newPost": "新帖子",
  "nip05Description": "您身份的驗證方法。您可以從提供商獲取NIP-05或使用您自己的域名。",
  "nip05Username": "NIP-05用戶名",
  "no": "否",
  "noFollowers": "沒有關注者",
  "noFollowing": "沒有關注任何人",
  "noPeople": "沒有人",
  "noPosts": "沒有帖子",
  "noResults": "沒有結果",
  "nosFeatures": "Nos功能",
  "nostrID": "Nostr ID",
  "nostrIDBech32Format": "Nostr ID (bech32格式)",
  "nostrIDHex": "Nostr ID (hex格式)",
  "nostrWhy": "為什麼選擇Nostr？",
  "not16Description": "在繼續之前，我們必須確認您至少年滿16歲。這是法律要求。",
  "not16Headline": "您年齡不夠無法使用Nos",
  "noteDeleted": "筆記已刪除",
  "notePublishError": "發布筆記時出錯",
  "notificationsEmpty": "您沒有通知",
  "nudity": "裸露",
  "offlinePublishing": "離線發布",
  "offlinePublishingDisabled": "離線發布已禁用",
  "offlinePublishingEnabled": "離線發布已啟用",
  "onceYouDelete": "一旦刪除您的帳戶，您將無法恢復它。",
  "openInBrowser": "在瀏覽器中打開",
  "or": "或",
  "over16": "您超過16歲嗎？",
  "peopleFollowingYou": "關注您的人",
  "peopleYouFollow": "您關注的人",
  "person": "人",
  "pickUsername": "選擇用戶名",
  "postDeleted": "帖子已刪除",
  "postDeleteFailed": "刪除帖子失敗",
  "postReply": "發布回復",
  "postThisNow": "立即發布",
  "postThisOnReconnect": "重新連接時發布",
  "pressHereToScan": "按此處掃描",
  "privateKeyBackupDescription": "此密鑰可訪問您的帳戶。將其放在安全的地方，如密碼管理器。",
  "privateKeyPlaceholder": "輸入您的nsec或hex私鑰",
  "privateKeyPrompt": "輸入您的私鑰",
  "privateKeyVisibility": "私鑰可見性",
  "profileUpdated": "個人資料已更新",
  "publicKeyDescription": "分享此密鑰讓其他人與您連接",
  "publishAndReconnect": "發布並重新連接",
  "publishedEvents": "已發布事件",
  "readMoreDescription": "在我們的網站上了解更多關於Nos和nostr標準的信息。",
  "reload": "重新加載",
  "relayInformation": "中繼信息",
  "remove": "移除",
  "removeImage": "移除圖片",
  "removeMedia": "移除媒體",
  "replyCount": "%@ 回復",
  "replyFormat": "回復 %@",
  "replyingTo": "回復",
  "replyingToYou": "回復您",
  "reportABug": "報告bug",
  "reportConfirmation": "您的報告已發送。謝謝！",
  "reportSuccessHeadline": "感謝您提交報告",
  "reportThisPost": "舉報此帖子",
  "reset": "重置",
  "reposted": "已轉發",
  "repostedYourPost": "轉發了您的帖子",
  "requestProfileError": "請求個人資料時出錯",
  "revealKey": "顯示密鑰",
  "saveKey": "保存密鑰",
  "saveKeySomewhereSafe": "將此密鑰保存在安全的地方",
  "saveSettingFailed": "保存設置失敗",
  "saveYourPrivateKey": "保存您的私鑰",
  "scanQRCode": "掃描二維碼",
  "searchEmpty": "未找到結果",
  "searchUsername": "搜索用戶名",
  "seemsLikeYouHaventPosted": "看起來您還沒有發布任何內容",
  "selectTopic": "選擇主題",
  "sensitiveContentWarningDescription": "此內容可能敏感。點擊查看。",
  "sensitiveImages": "敏感圖片",
  "sensitiveImagesShow": "顯示敏感圖片",
  "sensitiveImagesWarning": "此圖片可能包含敏感內容",
  "serverCapabilities": "服務器功能",
  "setup": "設置",
  "shareNpub": "分享npub",
  "shareProfile": "分享個人資料",
  "shareYourPublicKey": "分享您的公鑰",
  "sharKeyPublicly": "公開分享您的密鑰",
  "showAll": "顯示全部",
  "showMore": "顯示更多",
  "signUp": "註冊",
  "signUpForNosUsingExistingKey": "使用現有密鑰註冊Nos",
  "skipThisStep": "跳過此步驟",
  "somethingWentWrong": "出了點問題",
  "startMessaging": "開始發消息",
  "switch": "切換",
  "tapToScan": "點擊掃描",
  "termsOfService": "服務條款",
  "termsPartOne": "點擊繼續，即表示您同意我們的",
  "termsPartTwo": "服務條款",
  "thisPostHasBeenDeleted": "此帖子已被刪除",
  "time": "時間",
  "today": "今天",
  "tryAgain": "重試",
  "typeAReply": "輸入回復...",
  "unavailable": "不可用",
  "unflag": "取消標記",
  "unflagMessage": "您確定要取消標記此帖子嗎？",
  "unknownEvent": "未知事件",
  "updateFailedError": "更新失敗: %@",
  "usernameMustStartWithLetter": "用戶名必須以字母開頭",
  "usernameUnavailable": "用戶名不可用",
  "violence": "暴力",
  "warning": "警告",
  "webOfTrust": "信任網絡",
  "welcome": "歡迎！",
  "welcomeNostrich": "歡迎Nostrich！",
  "welcomeToFeed": "歡迎來到您的信息流！",
  "welcomeToNostr": "歡迎來到Nostr",
  "welcomeToNos": "歡迎來到Nos",
  "whatIsThis": "這是什麼？",
  "whyAmISeeingThis": "為什麼我會看到這個？",
  "word": "詞",
  "writeYourReply": "寫下您的回復...",
  "yes": "是",
  "yesItsMe": "是的，是我",
  "youDontFollowAnyone": "您沒有關注任何人",
  "youHaventLikedAnyPosts": "您還沒有點讚任何帖子",
  "yourBio": "您的簡介",
  "yourDisplayName": "您的顯示名稱",
  "yourFeed": "您的信息流",
  "yourLightnightAddress": "您的Lightning地址",
  "yourNIP05": "您的NIP-05",
  "youreSet": "您已設置完成！",
  "youveBlockedThisAuthor": "您已屏蔽此作者",
  "zapAddress": "Zap地址"
}

# Counter for tracking changes
added_count = 0
already_exists_count = 0

# Process each key in the strings dictionary
for key, value in data["strings"].items():
    if key in trad_chinese_translations:
        # Check if the key already has a Traditional Chinese translation
        if "zh-Hant" in value.get("localizations", {}):
            # Skip existing translations - don't replace
            already_exists_count += 1
        else:
            # Add the Traditional Chinese translation if it doesn't exist
            if "localizations" not in value:
                value["localizations"] = {}
            
            value["localizations"]["zh-Hant"] = {
                "stringUnit": {
                    "state": "translated",
                    "value": trad_chinese_translations[key]
                }
            }
            added_count += 1
            print(f"Added Traditional Chinese translation for '{key}': '{trad_chinese_translations[key]}'")

# Write the updated data back to the file
with tempfile.NamedTemporaryFile('w', encoding='utf-8', delete=False) as temp:
    json.dump(data, temp, ensure_ascii=False, indent=2)
    temp_name = temp.name

# Replace the original file with the new one
shutil.move(temp_name, file_path)

print(f"Completed: Added {added_count} Traditional Chinese translations, {already_exists_count} already existed (not replaced)")
print(f"Original file backed up at {backup_file}")