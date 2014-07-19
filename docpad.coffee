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

			# Author name used in copyrights and meta data
			author: "Павел Радьков"

			# Change to your disqus name or comment it out to disable comments
			disqus_shortname: "paulradzkov"

			# The website description (for SEO)
			description: """
				Заметки о веб-разработке Павла Радькова.
				"""

			# The website keywords (for SEO) separated by commas
			keywords: """
				Paul Radzkov, web-developer, blog, html, css
				"""

			email: "radzkov@gmail.com"

			googleAnalyticsId: "UA-29416794-1"

			googleAnalyticsDomain: "paulradzkov.com"

			# The website's styles
			styles: [
				'/css/template.css'
			]

			# The website's scripts
			scripts: [
				'/js/offscreenmenu.js'
				'/vendor/jquery.sticky.js'
				'/js/script.js'
				'/vendor/bootstrap/js/bootstrap.min.js'
				'/js/tooltip.js'
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

		# Get a collection of documents with a daterange
		# Using QueryEngine's setFilter
		getPostsByYear: (theYear) ->
			return @getCollection('articles').findAll({url: $startsWith: '/' + theYear},[{created_at:-1}])

		isActive: (s) ->
			# current links in navigation
			if @document.url == s
				" active "

		# Prepare Feed links and URLs
		prepareFeed: (s) ->
			s and (s
				.replace /href="\//g, "href=\"#{@site.url}/"
				.replace /src="\//g, "src=\"#{@site.url}/"
			)
			
		wspToDash: (s) ->
			s and (s 
				.replace /\ /g, "-"
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
			doc = @getFile({tag:tag})
			return doc?.get('url') or ''

	collections:
		articles: ->
			# get all posts by «kind», sort them by «created_at» and set to all «layout»
			@getCollection("html").findAllLive({kind:'article',publish:true},[{created_at:-1}]).on "add", (model) ->
				model.setMetaDefaults({layout:"default"})

		drafts: ->
			@getCollection("html").findAllLive({kind:'article',publish:false},[{created_at:-1}]).on "add", (model) ->
				model.setMetaDefaults({layout:"default"})

	# Plugins configurations
	plugins:
		sitemap:
			cachetime: 600000
			changefreq: 'weekly'
			priority: 0.5
		navlinks:
			collections:
				articles: -1
		cleanurls:
			static: true
			trailingSlashes: true
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