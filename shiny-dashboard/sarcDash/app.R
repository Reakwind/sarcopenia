# Launch the ShinyApp (Do not remove this comment)
# To deploy, run: rsconnect::deployApp()
# Or use the blue button on top of this file

# Load the package (production deployment)
library(sarcDash)

# Set production mode
options("golem.app.prod" = TRUE)

# Run the app
sarcDash::run_app() # add parameters here (if any)