local config = {}

config.sequenceTimeout = 0.4
config.windowSelectionTimeout = 0.6

config.windowSelectionMap = {
	a = "1",
	s = "2",
	d = "3",
	f = "4",
}

config.appMappings = {
	c = { name = "Google Chrome", bundleID = "com.google.Chrome" },
	h = { name = "Chromium", bundleID = "org.chromium.Chromium" },
	b = { name = "Brave Browser", bundleID = "com.brave.Browser" },
	i = { name = "iTerm", bundleID = "com.googlecode.iterm2" },
	a = { name = "Arc", bundleID = "company.thebrowser.Browser" },
	d = { name = "Discord", bundleID = "com.hnc.Discord" },
	v = { name = "Visual Studio Code", bundleID = "com.microsoft.VSCode" },
	g = { name = "ChatGPT", bundleID = "com.openai.chat" },
	o = { name = "Obsidian", bundleID = "md.obsidian" },
	k = { name = "Docker", bundleID = "com.docker.docker" },
	t = { name = "Postman", bundleID = "com.postmanlabs.mac" },
	n = { name = "Notion", bundleID = "notion.id" },
}

return config
