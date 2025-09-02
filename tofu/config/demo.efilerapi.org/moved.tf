moved {
  from = module.database
  to   = module.efiler_api.module.database
}
moved {
  from = module.logging
  to   = module.efiler_api.module.logging
}
moved {
  from = module.secrets
  to   = module.efiler_api.module.secrets
}
moved {
  from = module.vpc
  to   = module.efiler_api.module.vpc
}
moved {
  from = module.web
  to   = module.efiler_api.module.web
}
moved {
  from = module.workers
  to   = module.efiler_api.module.workers
}
