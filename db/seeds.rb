AI_TOOLS = [
  { domain: "chat.openai.com",      name: "ChatGPT",        category: "chat",    risk_level: "high" },
  { domain: "chatgpt.com",          name: "ChatGPT",        category: "chat",    risk_level: "high" },
  { domain: "claude.ai",            name: "Claude",         category: "chat",    risk_level: "medium" },
  { domain: "gemini.google.com",    name: "Gemini",         category: "chat",    risk_level: "medium" },
  { domain: "bard.google.com",      name: "Gemini (old)",   category: "chat",    risk_level: "medium" },
  { domain: "copilot.microsoft.com",name: "Copilot",        category: "chat",    risk_level: "medium" },
  { domain: "perplexity.ai",        name: "Perplexity",     category: "search",  risk_level: "medium" },
  { domain: "you.com",              name: "You.com",        category: "search",  risk_level: "low" },
  { domain: "phind.com",            name: "Phind",          category: "code",    risk_level: "medium" },
  { domain: "cursor.sh",            name: "Cursor",         category: "code",    risk_level: "high" },
  { domain: "character.ai",         name: "Character.AI",   category: "chat",    risk_level: "high" },
  { domain: "poe.com",              name: "Poe",            category: "chat",    risk_level: "medium" },
  { domain: "writesonic.com",       name: "Writesonic",     category: "writing", risk_level: "medium" },
  { domain: "jasper.ai",            name: "Jasper",         category: "writing", risk_level: "medium" },
  { domain: "copy.ai",              name: "Copy.ai",        category: "writing", risk_level: "medium" },
  { domain: "midjourney.com",       name: "Midjourney",     category: "image",   risk_level: "low" },
  { domain: "runway.com",           name: "RunwayML",       category: "image",   risk_level: "low" },
  { domain: "pika.art",             name: "Pika",           category: "image",   risk_level: "low" },
  { domain: "suno.com",             name: "Suno AI",        category: "other",   risk_level: "low" },
  { domain: "elevenlabs.io",        name: "ElevenLabs",     category: "other",   risk_level: "medium" }
].freeze

puts "Seeding AI tools..."
AI_TOOLS.each do |tool_data|
  AiTool.find_or_create_by!(domain: tool_data[:domain]) do |tool|
    tool.name       = tool_data[:name]
    tool.category   = tool_data[:category]
    tool.risk_level = tool_data[:risk_level]
    tool.approved   = false
  end
end
puts "  #{AiTool.count} AI tools seeded."

admin_email = ENV.fetch("ADMIN_EMAIL", "admin@example.com")
puts "Seeding admin user: #{admin_email}"
User.find_or_create_by!(email: admin_email) do |user|
  user.name  = "Admin"
  user.role  = "admin"
  user.token = "usr_#{SecureRandom.hex(16)}"
end
puts "  Admin user ready."
