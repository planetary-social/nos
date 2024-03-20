RELEASE_XCCONFIG="${PROJECT_DIR}/Nos/Assets/ProductionSecrets.xcconfig"
EMPTY_XCCONFIG="${PROJECT_DIR}/Nos/Assets/EmptySecrets.xcconfig"
DEV_XCCONFIG="${PROJECT_DIR}/Nos/Assets/DevSecrets.xcconfig"
DESTINATION="${PROJECT_DIR}/Nos/Assets/Secrets.xcconfig"


if [ "$CONFIGURATION" == "Debug" ] && [ -f "$DEBUG_XCCONFIG" ]; then
    rsync -t $EMPTY_XCCONFIG $DESTINATION
    echo "Copied empty config"
elif [ "$CONFIGURATION" == "Release" ] && [ -f "$RELEASE_XCCONFIG" ]; then
    rsync -t $RELEASE_XCCONFIG $DESTINATION
    echo "Copied release config"
elif [ "$CONFIGURATION" == "Staging" ] && [ -f "$RELEASE_XCCONFIG" ]; then
    rsync -t $RELEASE_XCCONFIG $DESTINATION
    echo "Copied release config"
elif [ "$CONFIGURATION" == "Dev" ] && [ -f "$DEV_XCCONFIG" ]; then
    rsync -t $DEV_XCCONFIG $DESTINATION
    echo "Copied dev config"
else
    rsync -t $EMPTY_XCCONFIG $DESTINATION
    echo "Copied empty config"
fi
