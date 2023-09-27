RELEASE_XCCONFIG="${PROJECT_DIR}/Nos/Assets/ProductionSecrets.xcconfig"
DEBUG_XCCONFIG="${PROJECT_DIR}/Nos/Assets/StagingSecrets.xcconfig"
EMPTY_XCCONFIG="${PROJECT_DIR}/Nos/Assets/EmptySecrets.xcconfig"
DESTINATION="${PROJECT_DIR}/Nos/Assets/Secrets.xcconfig"


if [ "$CONFIGURATION" == "Debug" ] && [ -f "$DEBUG_XCCONFIG" ]; then
    rsync -t $DEBUG_XCCONFIG $DESTINATION
    echo "Copied debug config"
elif [ "$CONFIGURATION" == "Release" ] && [ -f "$RELEASE_XXCONFIG" ]; then
    rsync -t $RELEASE_XCCONFIG $DESTINATION
    echo "Copied release config"
else
    rsync -t $EMPTY_XCCONFIG $DESTINATION
    echo "Copied empty config"
fi
