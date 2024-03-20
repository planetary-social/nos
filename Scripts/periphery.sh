if ! command -v periphery &> /dev/null
then
    echo "periphery could not be found. For installation instructions, see https://github.com/peripheryapp/periphery"
    exit 1
fi
periphery scan --retain-swift-ui-previews --report-exclude **/Generated/*.swift