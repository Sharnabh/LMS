#!/bin/bash

# Set the necessary environment variables for widget extension
export CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION=YES
export ENABLE_WIDGET_EXTENSION=YES

# Print environment for debugging
echo "Widget build settings applied:"
echo "CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION=$CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION"
echo "ENABLE_WIDGET_EXTENSION=$ENABLE_WIDGET_EXTENSION"

# If the target is the widget extension, make specific adjustments
if [[ "$PRODUCT_NAME" == *"Widgit"* || "$PRODUCT_NAME" == *"Widget"* ]]; then
    echo "Building widget extension: $PRODUCT_NAME"
    
    # Ensure widget entitlements file is properly configured
    if [ -f "$SRCROOT/PustaklayaWidgitExtension.entitlements" ]; then
        echo "Widget entitlements file found"
    else
        echo "Warning: Widget entitlements file not found"
    fi
fi

# Exit with success to continue the build
exit 0 