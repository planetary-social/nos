#!/usr/bin/env python3
import json
import os
import tempfile
import shutil

# Path to the Localizable.xcstrings file
file_path = '/Users/rabble/code/verse/nos/Nos/Assets/Localization/Localizable.xcstrings'

# Create a backup of the original file
backup_file = file_path + '.es.bak'
shutil.copy2(file_path, backup_file)
print(f"Created backup at {backup_file}")

# Load the translations file (since we'll be modifying it, we need to load it completely)
with open(file_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Define Spanish translations here
spanish_translations = {
  "acceptTermsAndPrivacy": "Al continuar, acepto los [Términos de servicio](https://nos.social/terms-of-service) y la [Política de privacidad](https://nos.social/privacy)",
  "accountPartialSuccessDescription": "La aplicación no pudo guardar el nombre de visualización o nombre de usuario que elegiste. Puedes configurarlos más tarde en tu perfil.",
  "accountPartialSuccessHeadline": "Has configurado tu cuenta, pero...",
  "accountSuccessDescription": "Ahora que sabes quién eres en Nostr, ¡encontremos a otras personas para seguir!",
  "accountSuccessHeadline": "¡Has configurado tu cuenta!",
  "addListsDescription": "Añade listas a tu feed para filtrar por tema.",
  "ageVerificationDescription": "Por razones legales, debemos asegurarnos de que tienes más de esta edad para usar Nos.",
  "ageVerificationHeadline": "¿Tienes más de 16 años?",
  "alreadyHaveANIP05": "No, gracias. Ya tengo un NIP-05",
  "anyRelaysSupportingNIP40": "Ninguno de tus relés admite mensajes que caducan. Añade uno e inténtalo de nuevo.",
  "anErrorOccurred": "Ha ocurrido un error.",
  "bioPlaceholder": "Cuéntanos un poco sobre ti...",
  "buildYourNetworkDescription": "Nostr mejora cuando sigues a personas. ¡Llenemos tu feed!",
  "buildYourNetworkHeadline": "Construye tu red",
  "cantSaveYourUsername": "No se puede guardar tu nombre de usuario",
  "chooseNIP05Provider": "Elige un proveedor NIP-05",
  "chooseStrongKeyphrase": "Elige una frase de contraseña fuerte",
  "clickToViewSensitiveContent": "Haz clic para ver el contenido sensible",
  "completeSetup": "Completar configuración",
  "confirming": "Confirmando...",
  "connecting": "Conectando...",
  "contentHiddenWarning": "Este contenido está oculto porque no es apropiado para todos los espectadores",
  "copyFailed": "Fallo en la copia",
  "copyKey": "Copiar clave",
  "copyNpub": "Copiar npub",
  "createNewKey": "Crear nueva clave",
  "createPublishedBy": "Creado %@ - Publicado por %@",
  "createANewPost": "Crear una nueva publicación",
  "defaultContentWarning": "Contenido sensible",
  "defaultDisplayName": "Nuevo Nostronaut",
  "defaults": "Predeterminados",
  "deleteAccountQuestion": "¿Eliminar cuenta?",
  "deleteConfirmation": "¿Estás seguro de que quieres eliminar esto?",
  "deleteUndoneWarning": "Esta acción no se puede deshacer.",
  "disconnected": "Desconectado",
  "displayNamePlaceholder": "Tu nombre de visualización",
  "displayNamePrompt": "¿Cómo quieres que te conozcan los demás?",
  "dontHaveNpub": "¿No tienes npub? ¡Crea uno nuevo!",
  "dontLoseYourKey": "¡No pierdas tu clave!",
  "editAccount": "Editar cuenta",
  "editDisplayName": "Editar nombre de visualización",
  "editUsername": "Editar nombre de usuario",
  "emptyFeed": "Feed vacío",
  "enterDisplayName": "Introduce un nombre de visualización",
  "enterUsernamePlaceholder": "Introduce un nombre de usuario",
  "enterYourPrivateKey": "Introduce tu clave privada",
  "eventCouldNotBeDecrypted": "El mensaje no pudo ser descifrado",
  "eventRemotelyDeleted": "Esta publicación ha sido eliminada por el autor",
  "events": "Eventos",
  "everyone": "Todos",
  "expirationTime": "Tiempo de caducidad",
  "feedEmpty": "¡Tu feed está vacío!",
  "feedEmptyDescription": "Encuentra personas para seguir y llenar tu feed",
  "feedOfPeopleIFollow": "Feed de personas que sigo",
  "feedsSelection": "Selección de feeds",
  "filterWarning": "El contenido puede contener elementos violentos, gráficos o sexuales",
  "findFriendsDescription": "Encuentra amigos pidiéndoles directamente que se conecten.",
  "findFriendsHeadline": "Encontrar amigos",
  "flagAsSpam": "Marcar como spam",
  "flagConfirm": "Confirmar marca",
  "flagInappropriate": "Marcar como inapropiado",
  "flagPrompt": "¿Por qué marcas esta publicación?",
  "flagReason": "Razón de la marca",
  "flagThisAuthor": "Marcar a este autor",
  "flagThisPost": "Marcar esta publicación",
  "followFormat": "Seguir a %@",
  "followingFormat": "Siguiendo a %@",
  "generateNew": "Generar nuevo",
  "giftedUserSignup": "Has recibido una suscripción de prueba gratuita",
  "goToFeed": "Ir al feed",
  "harassing": "Acoso",
  "hide": "Ocultar",
  "iAcceptTheTerms": "Acepto los términos",
  "iAmOver16": "Tengo más de 16 años",
  "illegal": "Ilegal",
  "importNsec": "Importar nsec",
  "importNsecDescription": "Inicia sesión con una clave Nostr existente",
  "inNewPost": "En nueva publicación",
  "inappropriate": "Inapropiado",
  "incorrectPrivateKey": "Clave privada incorrecta",
  "invalidLink": "Enlace inválido",
  "joined": "Se unió",
  "keyPhraseHint": "Esto se usa para cifrar tu clave privada, así que asegúrate de que sea fuerte y única para ti.",
  "keyphraseHint": "Usa una frase de contraseña única que puedas recordar",
  "keywordSearch": "Búsqueda por palabra clave",
  "keywordSearchPlaceholder": "Buscar palabras clave",
  "leaveAComment": "Deja un comentario...",
  "letsGetYouSet": "¡Vamos a configurarte!",
  "likes": "Me gusta",
  "loading": "Cargando...",
  "manageLists": "Gestionar listas",
  "manageSettings": "Administrar configuración",
  "message": "Mensaje",
  "messagesHiddenWarning": "Mensajes ocultos",
  "missingLightningAddress": "Dirección Lightning faltante",
  "moderation": "Moderación",
  "myFeed": "Mi feed",
  "name": "Nombre",
  "newPost": "Nueva publicación",
  "nip05Description": "Un método de verificación para tu identidad. Puedes obtener un NIP-05 de un proveedor o usar tu propio dominio.",
  "nip05Username": "Nombre de usuario NIP-05",
  "no": "No",
  "noFollowers": "Sin seguidores",
  "noFollowing": "No sigue a nadie",
  "noPeople": "Sin personas",
  "noPosts": "Sin publicaciones",
  "noResults": "Sin resultados",
  "nosFeatures": "Características de Nos",
  "nostrID": "ID de Nostr",
  "nostrIDBech32Format": "ID de Nostr (formato bech32)",
  "nostrIDHex": "ID de Nostr (formato hex)",
  "nostrWhy": "¿Por qué Nostr?",
  "not16Description": "Antes de continuar, debemos confirmar que tienes al menos 16 años. Es un requisito legal.",
  "not16Headline": "No tienes la edad suficiente para usar Nos",
  "noteDeleted": "Nota eliminada",
  "notePublishError": "Error al publicar la nota",
  "notificationsEmpty": "No tienes notificaciones",
  "nudity": "Desnudez",
  "offlinePublishing": "Publicación sin conexión",
  "offlinePublishingDisabled": "Publicación sin conexión desactivada",
  "offlinePublishingEnabled": "Publicación sin conexión activada",
  "onceYouDelete": "Una vez que eliminas tu cuenta, no podrás recuperarla.",
  "openInBrowser": "Abrir en navegador",
  "or": "o",
  "over16": "¿Tienes más de 16 años?",
  "peopleFollowingYou": "Personas que te siguen",
  "peopleYouFollow": "Personas que sigues",
  "person": "Persona",
  "pickUsername": "Elige un nombre de usuario",
  "postDeleted": "Publicación eliminada",
  "postDeleteFailed": "Error al eliminar la publicación",
  "postReply": "Publicar respuesta",
  "postThisNow": "Publicar ahora",
  "postThisOnReconnect": "Publicar al reconectar",
  "pressHereToScan": "Presiona aquí para escanear",
  "privateKeyBackupDescription": "Esta clave da acceso a tu cuenta. Guárdala en un lugar seguro como un gestor de contraseñas.",
  "privateKeyPlaceholder": "Introduce tu clave privada nsec o hex",
  "privateKeyPrompt": "Introduce tu clave privada",
  "privateKeyVisibility": "Visibilidad de clave privada",
  "profileUpdated": "Perfil actualizado",
  "publicKeyDescription": "Comparte esta clave para permitir que otros se conecten contigo",
  "publishAndReconnect": "Publicar y reconectar",
  "publishedEvents": "Eventos publicados",
  "readMoreDescription": "Aprende más sobre Nos y el estándar nostr en nuestro sitio web.",
  "reload": "Recargar",
  "relayInformation": "Información de relés",
  "remove": "Eliminar",
  "removeImage": "Eliminar imagen",
  "removeMedia": "Eliminar medios",
  "replyCount": "%@ respuestas",
  "replyFormat": "Responder a %@",
  "replyingTo": "Respondiendo a",
  "replyingToYou": "Te responde",
  "reportABug": "Informar de un error",
  "reportConfirmation": "Tu informe ha sido enviado. ¡Gracias!",
  "reportSuccessHeadline": "Gracias por enviar tu informe",
  "reportThisPost": "Informar sobre esta publicación",
  "reset": "Reiniciar",
  "reposted": "Reposteado",
  "repostedYourPost": "ha reposteado tu publicación",
  "requestProfileError": "Error al solicitar perfil",
  "revealKey": "Revelar clave",
  "saveKey": "Guardar clave",
  "saveKeySomewhereSafe": "Guarda esta clave en un lugar seguro",
  "saveSettingFailed": "Error al guardar la configuración",
  "saveYourPrivateKey": "Guarda tu clave privada",
  "scanQRCode": "Escanear código QR",
  "searchEmpty": "No se encontraron resultados",
  "searchUsername": "Buscar nombre de usuario",
  "seemsLikeYouHaventPosted": "Parece que aún no has publicado nada",
  "selectTopic": "Seleccionar tema",
  "sensitiveContentWarningDescription": "Este contenido puede ser sensible. Toca para ver.",
  "sensitiveImages": "Imágenes sensibles",
  "sensitiveImagesShow": "Mostrar imágenes sensibles",
  "sensitiveImagesWarning": "Esta imagen puede contener contenido sensible",
  "serverCapabilities": "Capacidades del servidor",
  "setup": "Configuración",
  "shareNpub": "Compartir npub",
  "shareProfile": "Compartir perfil",
  "shareYourPublicKey": "Comparte tu clave pública",
  "sharKeyPublicly": "Comparte tu clave públicamente",
  "showAll": "Mostrar todo",
  "showMore": "Mostrar más",
  "signUp": "Registrarse",
  "signUpForNosUsingExistingKey": "Regístrate en Nos con una clave existente",
  "skipThisStep": "Omitir este paso",
  "somethingWentWrong": "Algo salió mal",
  "startMessaging": "Comenzar mensajería",
  "switch": "Cambiar",
  "tapToScan": "Toca para escanear",
  "termsOfService": "Términos de servicio",
  "termsPartOne": "Al hacer clic en Continuar, aceptas nuestros",
  "termsPartTwo": "Términos de servicio",
  "thisPostHasBeenDeleted": "Esta publicación ha sido eliminada",
  "time": "Tiempo",
  "today": "Hoy",
  "tryAgain": "Intentar de nuevo",
  "typeAReply": "Escribe una respuesta...",
  "unavailable": "No disponible",
  "unflag": "Quitar marca",
  "unflagMessage": "¿Estás seguro de que quieres quitar la marca de esta publicación?",
  "unknownEvent": "Evento desconocido",
  "updateFailedError": "Error en la actualización: %@",
  "usernameMustStartWithLetter": "El nombre de usuario debe comenzar con una letra",
  "usernameUnavailable": "Nombre de usuario no disponible",
  "violence": "Violencia",
  "warning": "Advertencia",
  "webOfTrust": "Red de confianza",
  "welcome": "¡Bienvenido!",
  "welcomeNostrich": "¡Bienvenido Nostrich!",
  "welcomeToFeed": "¡Bienvenido a tu feed!",
  "welcomeToNostr": "Bienvenido a Nostr",
  "welcomeToNos": "Bienvenido a Nos",
  "whatIsThis": "¿Qué es esto?",
  "whyAmISeeingThis": "¿Por qué estoy viendo esto?",
  "word": "Palabra",
  "writeYourReply": "Escribe tu respuesta...",
  "yes": "Sí",
  "yesItsMe": "Sí, soy yo",
  "youDontFollowAnyone": "No sigues a nadie",
  "youHaventLikedAnyPosts": "Aún no te ha gustado ninguna publicación",
  "yourBio": "Tu biografía",
  "yourDisplayName": "Tu nombre de visualización",
  "yourFeed": "Tu feed",
  "yourLightnightAddress": "Tu dirección Lightning",
  "yourNIP05": "Tu NIP-05",
  "youreSet": "¡Estás listo!",
  "youveBlockedThisAuthor": "Has bloqueado a este autor",
  "zapAddress": "Dirección Zap"
}

# Counter for tracking changes
added_count = 0
already_exists_count = 0

# Process each key in the strings dictionary
for key, value in data["strings"].items():
    if key in spanish_translations:
        # Check if the key already has a Spanish translation
        if "es" in value.get("localizations", {}):
            current_translation = value["localizations"]["es"]["stringUnit"]["value"]
            if current_translation != spanish_translations[key]:
                print(f"Key '{key}' already has Spanish translation: '{current_translation}', replacing with '{spanish_translations[key]}'")
                value["localizations"]["es"]["stringUnit"]["value"] = spanish_translations[key]
                added_count += 1
            else:
                already_exists_count += 1
        else:
            # Add the Spanish translation if it doesn't exist
            if "localizations" not in value:
                value["localizations"] = {}
            
            value["localizations"]["es"] = {
                "stringUnit": {
                    "state": "translated",
                    "value": spanish_translations[key]
                }
            }
            added_count += 1
            print(f"Added Spanish translation for '{key}': '{spanish_translations[key]}'")

# Write the updated data back to the file
with tempfile.NamedTemporaryFile('w', encoding='utf-8', delete=False) as temp:
    json.dump(data, temp, ensure_ascii=False, indent=2)
    temp_name = temp.name

# Replace the original file with the new one
shutil.move(temp_name, file_path)

print(f"Completed: Added {added_count} Spanish translations, {already_exists_count} already existed")
print(f"Original file backed up at {backup_file}")