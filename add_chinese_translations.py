#!/usr/bin/env python3
import json
import os
import tempfile
import shutil

# Path to the Localizable.xcstrings file
file_path = '/Users/rabble/code/verse/nos/Nos/Assets/Localization/Localizable.xcstrings'

# Create a backup of the original file
backup_file = file_path + '.zh-Hans.bak'
shutil.copy2(file_path, backup_file)
print(f"Created backup at {backup_file}")

# Load the translations file (since we'll be modifying it, we need to load it completely)
with open(file_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Define Simplified Chinese translations here
chinese_translations = {
  "acceptTermsAndPrivacy": "继续即表示我接受[服务条款](https://nos.social/terms-of-service)和[隐私政策](https://nos.social/privacy)",
  "accountPartialSuccessDescription": "应用无法保存您选择的显示名称或用户名。您可以稍后在个人资料中设置它们。",
  "accountPartialSuccessHeadline": "您已设置好账户，但是...",
  "accountSuccessDescription": "现在您已经知道自己在Nostr上的身份，让我们找其他人关注吧！",
  "accountSuccessHeadline": "您已成功设置账户！",
  "addListsDescription": "将列表添加到您的信息流以按主题过滤。",
  "ageVerificationDescription": "出于法律原因，我们必须确保您年满此年龄才能使用Nos。",
  "ageVerificationHeadline": "您是否超过16岁？",
  "alreadyHaveANIP05": "不，谢谢。我已经有NIP-05了",
  "anyRelaysSupportingNIP40": "您的中继服务器都不支持过期消息。请添加一个并重试。",
  "anErrorOccurred": "发生了错误。",
  "bioPlaceholder": "告诉我们一些关于您的信息...",
  "buildYourNetworkDescription": "当您关注他人时，Nostr会变得更好。让我们填充您的信息流吧！",
  "buildYourNetworkHeadline": "建立您的网络",
  "cantSaveYourUsername": "无法保存您的用户名",
  "chooseNIP05Provider": "选择NIP-05提供商",
  "chooseStrongKeyphrase": "选择一个强密码短语",
  "clickToViewSensitiveContent": "点击查看敏感内容",
  "completeSetup": "完成设置",
  "confirming": "确认中...",
  "connecting": "连接中...",
  "contentHiddenWarning": "此内容已隐藏，因为它不适合所有观众",
  "copyFailed": "复制失败",
  "copyKey": "复制密钥",
  "copyNpub": "复制npub",
  "createNewKey": "创建新密钥",
  "createPublishedBy": "创建于 %@ - 发布者 %@",
  "createANewPost": "创建新帖子",
  "defaultContentWarning": "敏感内容",
  "defaultDisplayName": "新Nostronaut",
  "defaults": "默认值",
  "deleteAccountQuestion": "删除账户？",
  "deleteConfirmation": "您确定要删除这个吗？",
  "deleteUndoneWarning": "此操作无法撤销。",
  "disconnected": "已断开连接",
  "displayNamePlaceholder": "您的显示名称",
  "displayNamePrompt": "您希望别人如何认识您？",
  "dontHaveNpub": "没有npub？创建一个新的！",
  "dontLoseYourKey": "不要丢失您的密钥！",
  "editAccount": "编辑账户",
  "editDisplayName": "编辑显示名称",
  "editUsername": "编辑用户名",
  "emptyFeed": "空信息流",
  "enterDisplayName": "输入显示名称",
  "enterUsernamePlaceholder": "输入用户名",
  "enterYourPrivateKey": "输入您的私钥",
  "eventCouldNotBeDecrypted": "消息无法解密",
  "eventRemotelyDeleted": "此帖子已被作者删除",
  "events": "事件",
  "everyone": "所有人",
  "expirationTime": "过期时间",
  "feedEmpty": "您的信息流是空的！",
  "feedEmptyDescription": "寻找人关注以填充您的信息流",
  "feedOfPeopleIFollow": "我关注的人的信息流",
  "feedsSelection": "信息流选择",
  "filterWarning": "内容可能包含暴力、图像或性内容",
  "findFriendsDescription": "通过直接请求他们连接来找朋友。",
  "findFriendsHeadline": "寻找朋友",
  "flagAsSpam": "标记为垃圾信息",
  "flagConfirm": "确认标记",
  "flagInappropriate": "标记为不适当",
  "flagPrompt": "为什么要标记这篇帖子？",
  "flagReason": "标记原因",
  "flagThisAuthor": "标记这位作者",
  "flagThisPost": "标记这篇帖子",
  "followFormat": "关注 %@",
  "followingFormat": "正在关注 %@",
  "generateNew": "生成新的",
  "giftedUserSignup": "您已收到免费试用订阅",
  "goToFeed": "前往信息流",
  "harassing": "骚扰",
  "hide": "隐藏",
  "iAcceptTheTerms": "我接受条款",
  "iAmOver16": "我已满16岁",
  "illegal": "违法",
  "importNsec": "导入nsec",
  "importNsecDescription": "使用现有Nostr密钥登录",
  "inNewPost": "在新帖子中",
  "inappropriate": "不适当",
  "incorrectPrivateKey": "私钥不正确",
  "invalidLink": "无效链接",
  "joined": "已加入",
  "keyPhraseHint": "这用于加密您的私钥，所以请确保它强大且对您是唯一的。",
  "keyphraseHint": "使用您能记住的唯一密码短语",
  "keywordSearch": "关键词搜索",
  "keywordSearchPlaceholder": "搜索关键词",
  "leaveAComment": "留下评论...",
  "letsGetYouSet": "让我们为您设置！",
  "likes": "喜欢",
  "loading": "加载中...",
  "manageLists": "管理列表",
  "manageSettings": "管理设置",
  "message": "消息",
  "messagesHiddenWarning": "消息已隐藏",
  "missingLightningAddress": "缺少Lightning地址",
  "moderation": "审核",
  "myFeed": "我的信息流",
  "name": "名称",
  "newPost": "新帖子",
  "nip05Description": "您身份的验证方法。您可以从提供商获取NIP-05或使用您自己的域名。",
  "nip05Username": "NIP-05用户名",
  "no": "否",
  "noFollowers": "没有关注者",
  "noFollowing": "没有关注任何人",
  "noPeople": "没有人",
  "noPosts": "没有帖子",
  "noResults": "没有结果",
  "nosFeatures": "Nos功能",
  "nostrID": "Nostr ID",
  "nostrIDBech32Format": "Nostr ID (bech32格式)",
  "nostrIDHex": "Nostr ID (hex格式)",
  "nostrWhy": "为什么选择Nostr？",
  "not16Description": "在继续之前，我们必须确认您至少年满16岁。这是法律要求。",
  "not16Headline": "您年龄不够无法使用Nos",
  "noteDeleted": "笔记已删除",
  "notePublishError": "发布笔记时出错",
  "notificationsEmpty": "您没有通知",
  "nudity": "裸露",
  "offlinePublishing": "离线发布",
  "offlinePublishingDisabled": "离线发布已禁用",
  "offlinePublishingEnabled": "离线发布已启用",
  "onceYouDelete": "一旦删除您的账户，您将无法恢复它。",
  "openInBrowser": "在浏览器中打开",
  "or": "或",
  "over16": "您超过16岁吗？",
  "peopleFollowingYou": "关注您的人",
  "peopleYouFollow": "您关注的人",
  "person": "人",
  "pickUsername": "选择用户名",
  "postDeleted": "帖子已删除",
  "postDeleteFailed": "删除帖子失败",
  "postReply": "发布回复",
  "postThisNow": "立即发布",
  "postThisOnReconnect": "重新连接时发布",
  "pressHereToScan": "按此处扫描",
  "privateKeyBackupDescription": "此密钥可访问您的账户。将其放在安全的地方，如密码管理器。",
  "privateKeyPlaceholder": "输入您的nsec或hex私钥",
  "privateKeyPrompt": "输入您的私钥",
  "privateKeyVisibility": "私钥可见性",
  "profileUpdated": "个人资料已更新",
  "publicKeyDescription": "分享此密钥让其他人与您连接",
  "publishAndReconnect": "发布并重新连接",
  "publishedEvents": "已发布事件",
  "readMoreDescription": "在我们的网站上了解更多关于Nos和nostr标准的信息。",
  "reload": "重新加载",
  "relayInformation": "中继信息",
  "remove": "移除",
  "removeImage": "移除图片",
  "removeMedia": "移除媒体",
  "replyCount": "%@ 回复",
  "replyFormat": "回复 %@",
  "replyingTo": "回复",
  "replyingToYou": "回复您",
  "reportABug": "报告bug",
  "reportConfirmation": "您的报告已发送。谢谢！",
  "reportSuccessHeadline": "感谢您提交报告",
  "reportThisPost": "举报此帖子",
  "reset": "重置",
  "reposted": "已转发",
  "repostedYourPost": "转发了您的帖子",
  "requestProfileError": "请求个人资料时出错",
  "revealKey": "显示密钥",
  "saveKey": "保存密钥",
  "saveKeySomewhereSafe": "将此密钥保存在安全的地方",
  "saveSettingFailed": "保存设置失败",
  "saveYourPrivateKey": "保存您的私钥",
  "scanQRCode": "扫描二维码",
  "searchEmpty": "未找到结果",
  "searchUsername": "搜索用户名",
  "seemsLikeYouHaventPosted": "看起来您还没有发布任何内容",
  "selectTopic": "选择主题",
  "sensitiveContentWarningDescription": "此内容可能敏感。点击查看。",
  "sensitiveImages": "敏感图片",
  "sensitiveImagesShow": "显示敏感图片",
  "sensitiveImagesWarning": "此图片可能包含敏感内容",
  "serverCapabilities": "服务器功能",
  "setup": "设置",
  "shareNpub": "分享npub",
  "shareProfile": "分享个人资料",
  "shareYourPublicKey": "分享您的公钥",
  "sharKeyPublicly": "公开分享您的密钥",
  "showAll": "显示全部",
  "showMore": "显示更多",
  "signUp": "注册",
  "signUpForNosUsingExistingKey": "使用现有密钥注册Nos",
  "skipThisStep": "跳过此步骤",
  "somethingWentWrong": "出了点问题",
  "startMessaging": "开始发消息",
  "switch": "切换",
  "tapToScan": "点击扫描",
  "termsOfService": "服务条款",
  "termsPartOne": "点击继续，即表示您同意我们的",
  "termsPartTwo": "服务条款",
  "thisPostHasBeenDeleted": "此帖子已被删除",
  "time": "时间",
  "today": "今天",
  "tryAgain": "重试",
  "typeAReply": "输入回复...",
  "unavailable": "不可用",
  "unflag": "取消标记",
  "unflagMessage": "您确定要取消标记此帖子吗？",
  "unknownEvent": "未知事件",
  "updateFailedError": "更新失败: %@",
  "usernameMustStartWithLetter": "用户名必须以字母开头",
  "usernameUnavailable": "用户名不可用",
  "violence": "暴力",
  "warning": "警告",
  "webOfTrust": "信任网络",
  "welcome": "欢迎！",
  "welcomeNostrich": "欢迎Nostrich！",
  "welcomeToFeed": "欢迎来到您的信息流！",
  "welcomeToNostr": "欢迎来到Nostr",
  "welcomeToNos": "欢迎来到Nos",
  "whatIsThis": "这是什么？",
  "whyAmISeeingThis": "为什么我会看到这个？",
  "word": "词",
  "writeYourReply": "写下您的回复...",
  "yes": "是",
  "yesItsMe": "是的，是我",
  "youDontFollowAnyone": "您没有关注任何人",
  "youHaventLikedAnyPosts": "您还没有点赞任何帖子",
  "yourBio": "您的简介",
  "yourDisplayName": "您的显示名称",
  "yourFeed": "您的信息流",
  "yourLightnightAddress": "您的Lightning地址",
  "yourNIP05": "您的NIP-05",
  "youreSet": "您已设置完成！",
  "youveBlockedThisAuthor": "您已屏蔽此作者",
  "zapAddress": "Zap地址"
}

# Counter for tracking changes
added_count = 0
already_exists_count = 0

# Process each key in the strings dictionary
for key, value in data["strings"].items():
    if key in chinese_translations:
        # Check if the key already has a Simplified Chinese translation
        if "zh-Hans" in value.get("localizations", {}):
            # Skip existing translations - don't replace
            already_exists_count += 1
        else:
            # Add the Chinese translation if it doesn't exist
            if "localizations" not in value:
                value["localizations"] = {}
            
            value["localizations"]["zh-Hans"] = {
                "stringUnit": {
                    "state": "translated",
                    "value": chinese_translations[key]
                }
            }
            added_count += 1
            print(f"Added Chinese translation for '{key}': '{chinese_translations[key]}'")

# Write the updated data back to the file
with tempfile.NamedTemporaryFile('w', encoding='utf-8', delete=False) as temp:
    json.dump(data, temp, ensure_ascii=False, indent=2)
    temp_name = temp.name

# Replace the original file with the new one
shutil.move(temp_name, file_path)

print(f"Completed: Added {added_count} Chinese translations, {already_exists_count} already existed (not replaced)")
print(f"Original file backed up at {backup_file}")