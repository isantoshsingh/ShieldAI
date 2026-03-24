# 1. Super admin (no organisation)
User.find_or_create_by!(email: ENV.fetch("SEED_SUPER_ADMIN_EMAIL")) do |u|
  u.name     = "Super Admin"
  u.role     = "super_admin"
  u.password = ENV.fetch("SEED_SUPER_ADMIN_PASSWORD")
end

# 2. First test organisation + org_admin
# Organisation#after_create seeds ai_tools automatically.
org = Organisation.find_or_create_by!(name: ENV.fetch("SEED_ORG_NAME")) do |o|
  o.active = true
end

User.find_or_create_by!(email: ENV.fetch("SEED_ORG_ADMIN_EMAIL")) do |u|
  u.name         = "Org Admin"
  u.role         = "org_admin"
  u.organisation = org
  u.password     = ENV.fetch("SEED_ORG_ADMIN_PASSWORD")
end
