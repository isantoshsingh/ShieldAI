// Import and register all your controllers from the controllers folder
import { application } from "controllers/application"

import RefreshController from "controllers/refresh_controller"
application.register("refresh", RefreshController)
