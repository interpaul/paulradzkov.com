# Requires
moment = require('moment')
moment.lang('ru')  # set locale to russian

# The DocPad Configuration File
# It is simply a CoffeeScript Object which is parsed by CSON
docpadConfig = {

	# =================================
	# Template Data
	# These are variables that will be accessible via our templates
	# To access one of these within our templates, refer to the FAQ: https://github.com/bevry/docpad/wiki/FAQ

	templateData:

		cutTag: '<!-- cut -->'

		# Specify some site properties
		site:
			# The production url of our website
			url: "http://paulradzkov.com"

			# Here are some old site urls that you would like to redirect from
			oldUrls: [
				'www.paulradzkov.com'
			]

			# The default title of our website
			title: "Павел Радьков"

			# RSS title of our website
			rssTitle: "Блог Павла Радькова"

			# The website description (for SEO)
			description: """
				Заметки о веб-разработке.
				"""

			# The website keywords (for SEO) separated by commas
			keywords: """
				Paul Radzkov, web-developer, blog, html, css
				"""

			author: "Павел Радьков"

			email: "radzkov@gmail.com"

			googleAnalyticsId: "UA-29416794-1"

			googleAnalyticsDomain: "paulradzkov.com"

			# The website's styles
			styles: [
				'/vendor/normalize.css'
				'/vendor/h5bp.css'
				'/css/github.css'
				'/css/caniuse.css'
				'/css/theme.css'
			]

			# The website's scripts
			scripts: [
				'/vendor/log.js'
				'/js/offscreenmenu.js'
				'/vendor/caniuse.js'
			]

		# -----------------------------
		# Helper Functions

		# Get the prepared site/document title
		# Often we would like to specify particular formatting to our page's title
		# we can apply that formatting here
		getPreparedTitle: ->
			# if we have a document title, then we should use that and suffix the site's title onto it
			if @document.title
				"#{@document.title} / #{@site.title}"
			# if our document does not have it's own title, then we should just use the site's title
			else
				@site.title

		# Get the prepared site/document description
		getPreparedDescription: ->
			# if we have a document description, then we should use that, otherwise use the site's description
			@document.description or @site.description

		# Get the prepared site/document keywords
		getPreparedKeywords: ->
			# Merge the document keywords with the site keywords
			@site.keywords.concat(@document.keywords or []).join(', ')

		getPreparedArticleTags: (tags) ->
			# Merge the document keywords with the site keywords
			tags.concat(tags or []).join(', ')

		# Format the passed date, by default format like: Thursday, November 29 2012 3:53 PM
		formatDate: (date,format='MM-DD-YYYY') ->
				return moment(date).format(format)

		# Prepare Feed links and URLs
		prepareFeed: (s) ->
			s and (s
				.replace /href="\//g, "href=\"#{@site.url}/"
				.replace /src="\//g, "src=\"#{@site.url}/"
			)

		# Post part before “cut”
		cuttedContent: (content) ->            
			if @hasReadMore content
				cutIdx = content.search @cutTag
				content[0..cutIdx-1]
			else
				content

		# Has “cut”?
		hasReadMore: (content) ->
			content and ((content.search @cutTag) isnt -1)

		getTagUrl: (tag) ->
			doc = docpad.getFile({tag:tag})
			return doc?.get('url') or ''

	collections:
		articles: ->
			# get all posts by «kind», sort them by «created_at» and set to all «layout»
			@getCollection("html").findAllLive({kind:'article',publish:true},[{created_at:-1}]).on "add", (model) ->
				model.setMetaDefaults({layout:"article"})

		drafts: ->
			@getCollection("html").findAllLive({kind:'article',publish:false},[{created_at:-1}]).on "add", (model) ->
				model.setMetaDefaults({layout:"article"})

	# Plugins configurations
	plugins:
		sitemap:
			cachetime: 600000
			changefreq: 'weekly'
			priority: 0.5
		navlinks:
			collections:
				articles: -1
		tags:
			extension: '.html.eco'
			injectDocumentHelper: (document) ->
				document.setMeta(
					layout: 'tagcloud'
					data:  """
						<%- @partial('tag', @) %>
						"""
				)

	# =================================
	# DocPad Events

	# Here we can define handlers for events that DocPad fires
	# You can find a full listing of events on the DocPad Wiki
	events:

		# Server Extend
		# Used to add our own custom routes to the server before the docpad routes are added
		serverExtend: (opts) ->
			# Extract the server from the options
			{server} = opts
			docpad = @docpad

			# As we are now running in an event,
			# ensure we are using the latest copy of the docpad configuraiton
			# and fetch our urls from it
			latestConfig = docpad.getConfig()
			oldUrls = latestConfig.templateData.site.oldUrls or []
			newUrl = latestConfig.templateData.site.url

			# Redirect any requests accessing one of our sites oldUrls to the new site url
			server.use (req,res,next) ->
				if req.headers.host in oldUrls
					res.redirect(newUrl+req.url, 301)
				else
					next()
}

# Export our DocPad Configuration
module.exports = docpadConfig