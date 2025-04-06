#!/usr/bin/env python3
import json
import os
import tempfile
import shutil

# Path to the Localizable.xcstrings file
file_path = '/Users/rabble/code/verse/nos/Nos/Assets/Localization/Localizable.xcstrings'

# Create a backup of the original file
backup_file = file_path + '.fr.bak'
shutil.copy2(file_path, backup_file)
print(f"Created backup at {backup_file}")

# Load the translations file (since we'll be modifying it, we need to load it completely)
with open(file_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Define French translations here
french_translations = {
  "acceptTermsAndPrivacy": "En poursuivant, j'accepte les [Conditions d'utilisation](https://nos.social/terms-of-service) et la [Politique de confidentialité](https://nos.social/privacy)",
  "accountPartialSuccessDescription": "L'application n'a pas pu sauvegarder le nom d'affichage ou le nom d'utilisateur que vous avez choisis. Vous pourrez les configurer plus tard dans votre profil.",
  "accountPartialSuccessHeadline": "Vous avez terminé la configuration de votre compte, mais...",
  "accountSuccessDescription": "Maintenant que vous savez qui vous êtes sur Nostr, trouvons d'autres personnes à suivre !",
  "accountSuccessHeadline": "Vous avez terminé la configuration de votre compte !",
  "addListsDescription": "Ajoutez des listes à votre flux pour filtrer par sujet.",
  "ageVerificationDescription": "Pour des raisons légales, nous devons nous assurer que vous avez plus de cet âge pour utiliser Nos.",
  "ageVerificationHeadline": "Avez-vous plus de 16 ans ?",
  "alreadyHaveANIP05": "Non merci. J'ai déjà un NIP-05",
  "anyRelaysSupportingNIP40": "Aucun de vos relais ne prend en charge les messages qui expirent. Ajoutez-en un et réessayez.",
  "anErrorOccurred": "Une erreur s'est produite.",
  "bioPlaceholder": "Parlez un peu de vous...",
  "buildYourNetworkDescription": "Nostr devient meilleur lorsque vous suivez des personnes. Remplissons votre flux !",
  "buildYourNetworkHeadline": "Construisez votre réseau",
  "cantSaveYourUsername": "Impossible d'enregistrer votre nom d'utilisateur",
  "chooseNIP05Provider": "Choisissez un fournisseur NIP-05",
  "chooseStrongKeyphrase": "Choisissez une phrase de passe forte",
  "clickToViewSensitiveContent": "Cliquez pour voir le contenu sensible",
  "completeSetup": "Terminer la configuration",
  "confirming": "Confirmation...",
  "connecting": "Connexion...",
  "contentHiddenWarning": "Ce contenu est masqué car il n'est pas approprié pour tous les spectateurs",
  "copyFailed": "Échec de la copie",
  "copyKey": "Copier la clé",
  "copyNpub": "Copier npub",
  "createNewKey": "Créer une nouvelle clé",
  "createPublishedBy": "Créé %@ - Publié par %@",
  "createANewPost": "Créer un nouveau post",
  "defaultContentWarning": "Contenu sensible",
  "defaultDisplayName": "Nouvel Nostronaut",
  "defaults": "Par défaut",
  "deleteAccountQuestion": "Supprimer le compte ?",
  "deleteConfirmation": "Êtes-vous sûr de vouloir supprimer ceci ?",
  "deleteUndoneWarning": "Cette action ne peut pas être annulée.",
  "disconnected": "Déconnecté",
  "displayNamePlaceholder": "Votre nom d'affichage",
  "displayNamePrompt": "Comment voulez-vous que les autres vous connaissent ?",
  "dontHaveNpub": "Vous n'avez pas de npub ? Créez-en un nouveau !",
  "dontLoseYourKey": "Ne perdez pas votre clé !",
  "editAccount": "Modifier le compte",
  "editDisplayName": "Modifier le nom d'affichage",
  "editUsername": "Modifier le nom d'utilisateur",
  "emptyFeed": "Flux vide",
  "enterDisplayName": "Entrez un nom d'affichage",
  "enterUsernamePlaceholder": "Entrez un nom d'utilisateur",
  "enterYourPrivateKey": "Entrez votre clé privée",
  "eventCouldNotBeDecrypted": "Le message n'a pas pu être déchiffré",
  "eventRemotelyDeleted": "Ce post a été supprimé par l'auteur",
  "events": "Événements",
  "everyone": "Tout le monde",
  "expirationTime": "Temps d'expiration",
  "feedEmpty": "Votre flux est vide !",
  "feedEmptyDescription": "Trouvez des personnes à suivre pour remplir votre flux",
  "feedOfPeopleIFollow": "Flux des personnes que je suis",
  "feedsSelection": "Sélection des flux",
  "filterWarning": "Le contenu peut contenir des éléments violents, graphiques ou sexuels",
  "findFriendsDescription": "Trouvez des amis en leur demandant directement de se connecter.",
  "findFriendsHeadline": "Trouver des amis",
  "flagAsSpam": "Signaler comme spam",
  "flagConfirm": "Confirmer le signalement",
  "flagInappropriate": "Signaler comme inapproprié",
  "flagPrompt": "Pourquoi signalez-vous ce post ?",
  "flagReason": "Raison du signalement",
  "flagThisAuthor": "Signaler cet auteur",
  "flagThisPost": "Signaler ce post",
  "followFormat": "Suivre %@",
  "followingFormat": "Suivant %@",
  "generateNew": "Générer nouveau",
  "giftedUserSignup": "Vous avez reçu un abonnement d'essai gratuit",
  "goToFeed": "Aller au flux",
  "harassing": "Harcèlement",
  "hide": "Masquer",
  "iAcceptTheTerms": "J'accepte les conditions",
  "iAmOver16": "J'ai plus de 16 ans",
  "illegal": "Illégal",
  "importNsec": "Importer nsec",
  "importNsecDescription": "Connectez-vous avec une clé Nostr existante",
  "inNewPost": "Dans un nouveau post",
  "inappropriate": "Inapproprié",
  "incorrectPrivateKey": "Clé privée incorrecte",
  "invalidLink": "Lien invalide",
  "joined": "Inscrit",
  "keyPhraseHint": "Ceci est utilisé pour crypter votre clé privée, alors assurez-vous qu'elle est forte et unique pour vous.",
  "keyphraseHint": "Utilisez une phrase de passe unique dont vous pouvez vous souvenir",
  "keywordSearch": "Recherche par mot-clé",
  "keywordSearchPlaceholder": "Rechercher des mots-clés",
  "leaveAComment": "Laissez un commentaire...",
  "letsGetYouSet": "Configurons votre compte !",
  "likes": "J'aime",
  "loading": "Chargement...",
  "manageLists": "Gérer les listes",
  "manageSettings": "Gérer les paramètres",
  "message": "Message",
  "messagesHiddenWarning": "Messages masqués",
  "missingLightningAddress": "Adresse Lightning manquante",
  "moderation": "Modération",
  "myFeed": "Mon flux",
  "name": "Nom",
  "newPost": "Nouveau post",
  "nip05Description": "Une méthode de vérification pour votre identité. Vous pouvez obtenir un NIP-05 auprès d'un fournisseur ou utiliser votre propre domaine.",
  "nip05Username": "Nom d'utilisateur NIP-05",
  "no": "Non",
  "noFollowers": "Aucun abonné",
  "noFollowing": "N'abonne personne",
  "noPeople": "Aucune personne",
  "noPosts": "Aucun post",
  "noResults": "Aucun résultat",
  "nosFeatures": "Fonctionnalités de Nos",
  "nostrID": "ID Nostr",
  "nostrIDBech32Format": "ID Nostr (format bech32)",
  "nostrIDHex": "ID Nostr (format hex)",
  "nostrWhy": "Pourquoi Nostr ?",
  "not16Description": "Avant de continuer, nous devons confirmer que vous avez au moins 16 ans. C'est une exigence légale.",
  "not16Headline": "Vous n'avez pas l'âge requis pour utiliser Nos",
  "noteDeleted": "Note supprimée",
  "notePublishError": "Erreur lors de la publication de la note",
  "notificationsEmpty": "Vous n'avez pas de notifications",
  "nudity": "Nudité",
  "offlinePublishing": "Publication hors ligne",
  "offlinePublishingDisabled": "Publication hors ligne désactivée",
  "offlinePublishingEnabled": "Publication hors ligne activée",
  "onceYouDelete": "Une fois que vous supprimez votre compte, vous ne pourrez pas le récupérer.",
  "openInBrowser": "Ouvrir dans le navigateur",
  "or": "ou",
  "over16": "Avez-vous plus de 16 ans ?",
  "peopleFollowingYou": "Personnes qui vous suivent",
  "peopleYouFollow": "Personnes que vous suivez",
  "person": "Personne",
  "pickUsername": "Choisissez un nom d'utilisateur",
  "postDeleted": "Post supprimé",
  "postDeleteFailed": "Échec de la suppression du post",
  "postReply": "Publier une réponse",
  "postThisNow": "Publier maintenant",
  "postThisOnReconnect": "Publier à la reconnexion",
  "pressHereToScan": "Appuyez ici pour scanner",
  "privateKeyBackupDescription": "Cette clé donne accès à votre compte. Placez-la dans un endroit sûr comme un gestionnaire de mots de passe.",
  "privateKeyPlaceholder": "Entrez votre clé privée nsec ou hex",
  "privateKeyPrompt": "Entrez votre clé privée",
  "privateKeyVisibility": "Visibilité de la clé privée",
  "profileUpdated": "Profil mis à jour",
  "publicKeyDescription": "Partagez cette clé pour permettre aux autres de se connecter avec vous",
  "publishAndReconnect": "Publier et reconnecter",
  "publishedEvents": "Événements publiés",
  "readMoreDescription": "En savoir plus sur Nos et le standard nostr sur notre site web.",
  "reload": "Recharger",
  "relayInformation": "Informations sur le relais",
  "remove": "Supprimer",
  "removeImage": "Supprimer l'image",
  "removeMedia": "Supprimer le média",
  "replyCount": "%@ réponses",
  "replyFormat": "Répondre à %@",
  "replyingTo": "Répondre à",
  "replyingToYou": "Vous répond",
  "reportABug": "Signaler un bug",
  "reportConfirmation": "Votre signalement a été envoyé. Merci !",
  "reportSuccessHeadline": "Merci d'avoir envoyé votre signalement",
  "reportThisPost": "Signaler ce post",
  "reset": "Réinitialiser",
  "reposted": "Reposté",
  "repostedYourPost": "a reposté votre message",
  "requestProfileError": "Erreur lors de la demande de profil",
  "revealKey": "Révéler la clé",
  "saveKey": "Enregistrer la clé",
  "saveKeySomewhereSafe": "Enregistrez cette clé dans un endroit sûr",
  "saveSettingFailed": "Échec de l'enregistrement des paramètres",
  "saveYourPrivateKey": "Enregistrez votre clé privée",
  "scanQRCode": "Scanner le code QR",
  "searchEmpty": "Aucun résultat trouvé",
  "searchUsername": "Rechercher un nom d'utilisateur",
  "seemsLikeYouHaventPosted": "Il semble que vous n'ayez encore rien posté",
  "selectTopic": "Sélectionner un sujet",
  "sensitiveContentWarningDescription": "Ce contenu peut être sensible. Tapez pour afficher.",
  "sensitiveImages": "Images sensibles",
  "sensitiveImagesShow": "Afficher les images sensibles",
  "sensitiveImagesWarning": "Cette image peut contenir du contenu sensible",
  "serverCapabilities": "Capacités du serveur",
  "setup": "Configuration",
  "shareNpub": "Partager npub",
  "shareProfile": "Partager le profil",
  "shareYourPublicKey": "Partagez votre clé publique",
  "sharKeyPublicly": "Partagez votre clé publiquement",
  "showAll": "Afficher tout",
  "showMore": "Afficher plus",
  "signUp": "S'inscrire",
  "signUpForNosUsingExistingKey": "Inscrivez-vous à Nos avec une clé existante",
  "skipThisStep": "Ignorer cette étape",
  "somethingWentWrong": "Quelque chose s'est mal passé",
  "startMessaging": "Commencer la messagerie",
  "switch": "Changer",
  "tapToScan": "Tapez pour scanner",
  "termsOfService": "Conditions d'utilisation",
  "termsPartOne": "En cliquant sur Continuer, vous acceptez nos",
  "termsPartTwo": "Conditions d'utilisation",
  "thisPostHasBeenDeleted": "Ce post a été supprimé",
  "time": "Temps",
  "today": "Aujourd'hui",
  "tryAgain": "Réessayer",
  "typeAReply": "Tapez une réponse...",
  "unavailable": "Indisponible",
  "unflag": "Retirer le signalement",
  "unflagMessage": "Êtes-vous sûr de vouloir retirer le signalement de ce post ?",
  "unknownEvent": "Événement inconnu",
  "updateFailedError": "Échec de la mise à jour : %@",
  "usernameMustStartWithLetter": "Le nom d'utilisateur doit commencer par une lettre",
  "usernameUnavailable": "Nom d'utilisateur indisponible",
  "violence": "Violence",
  "warning": "Avertissement",
  "webOfTrust": "Réseau de confiance",
  "welcome": "Bienvenue !",
  "welcomeNostrich": "Bienvenue Nostrich !",
  "welcomeToFeed": "Bienvenue dans votre flux !",
  "welcomeToNostr": "Bienvenue sur Nostr",
  "welcomeToNos": "Bienvenue sur Nos",
  "whatIsThis": "Qu'est-ce que c'est ?",
  "whyAmISeeingThis": "Pourquoi est-ce que je vois cela ?",
  "word": "Mot",
  "writeYourReply": "Écrivez votre réponse...",
  "yes": "Oui",
  "yesItsMe": "Oui, c'est moi",
  "youDontFollowAnyone": "Vous ne suivez personne",
  "youHaventLikedAnyPosts": "Vous n'avez encore aimé aucun post",
  "yourBio": "Votre bio",
  "yourDisplayName": "Votre nom d'affichage",
  "yourFeed": "Votre flux",
  "yourLightnightAddress": "Votre adresse Lightning",
  "yourNIP05": "Votre NIP-05",
  "youreSet": "Vous êtes prêt !",
  "youveBlockedThisAuthor": "Vous avez bloqué cet auteur",
  "zapAddress": "Adresse Zap"
}

# Counter for tracking changes
added_count = 0
already_exists_count = 0

# Process each key in the strings dictionary
for key, value in data["strings"].items():
    if key in french_translations:
        # Check if the key already has a French translation
        if "fr" in value.get("localizations", {}):
            current_translation = value["localizations"]["fr"]["stringUnit"]["value"]
            if current_translation != french_translations[key]:
                print(f"Key '{key}' already has French translation: '{current_translation}', replacing with '{french_translations[key]}'")
                value["localizations"]["fr"]["stringUnit"]["value"] = french_translations[key]
                added_count += 1
            else:
                already_exists_count += 1
        else:
            # Add the French translation if it doesn't exist
            if "localizations" not in value:
                value["localizations"] = {}
            
            value["localizations"]["fr"] = {
                "stringUnit": {
                    "state": "translated",
                    "value": french_translations[key]
                }
            }
            added_count += 1
            print(f"Added French translation for '{key}': '{french_translations[key]}'")

# Write the updated data back to the file
with tempfile.NamedTemporaryFile('w', encoding='utf-8', delete=False) as temp:
    json.dump(data, temp, ensure_ascii=False, indent=2)
    temp_name = temp.name

# Replace the original file with the new one
shutil.move(temp_name, file_path)

print(f"Completed: Added {added_count} French translations, {already_exists_count} already existed")
print(f"Original file backed up at {backup_file}")