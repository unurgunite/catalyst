# Require ameba cli which starts the inspection.
require "ameba/cli"

# Ameba extensions added as project dependencies.
# Rules are registered at compile time, so they only exist in a binary built
# from this file — a prebuilt ameba will not see them.
require "ameba-method_length"
