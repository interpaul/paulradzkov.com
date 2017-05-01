---
title: "Деплой Docpad-сайта на GitHub Pages"
excerpt: "Решение проблемы с абсолютными путями и автоматизация выкладки сайта на хостинг"
description: "Решение проблемы с абсолютными путями и автоматизация выкладки сайта на хостинг"
created_at: 2014-04-25
kind: article
publish: true
disqusid: deploy_docpad_site_to_github_pages
tags: [docpad, github pages]
og_image: '/i/og/og-paulradzkov-2014-deploy_docpad_site_to_github_pages.png'
---

При деплое [Docpad](http://docpad.org/)-сайта на [GitHub Pages](https://pages.github.com/) столкнулся с некоторыми проблемами.

1. Проблема с абсолютными путями: докпад по-умолчанию использует пути к ресурсам от корня домена, а на GH Pages url проекта будет выглядеть так `http://username.github.io/repository/`. Т.е. сайт находится в папке, а не в корне, и все пути к ресурсам недействительны. Конечно, можно купить собственное доменное имя, но это не мой случай. Нужно, чтобы на локалхосте url оставались абсолютными, а при деплое заменялись с учетом папки, в которую сайт деплоится.
2. [Плагин для деплоя](https://github.com/docpad/docpad-plugin-ghpages) не заработал сразу и без настроек, как обещает разработчик.

Так как у меня не всё прошло гладко и очевидно, решил написать эту инструкцию.

<!-- cut -->

## Проблема с абсолютными путями

Сначала разберёмся с абсолютными путями в докпаде.

Установим плагин [Get Url Plugin for DocPad](https://github.com/Hypercubed/docpad-plugin-geturl/).

Если ещё не создана, сделаем в конфиге докпада переменную `@site.url`:

```coffeescript
	templateData:
		site:
			# The production url of our website. Used in sitemap and rss feed
			url: "http://paulradzkov.github.io/docpad-simpleblog"
```

И добавим отдельную конфигурацию для «development» окружения:

```coffeescript
	# =================================
	# Environments

	environments:
		development:
			templateData:
				site:
					url: 'http://localhost:9778'
```

Эта переменная — `@site.url` — будет подставляться префиксом ко всем путям и ссылкам в зависимости от того, работаем мы на локалхосте или выкатываем сайт на хостинг.

Теперь нужно добавить хелпер «`@getUrl()`» ко всем «`href`» и «`src`» в шаблоне, в документах — везде, где встречаются абсолютные пути.

Например, было:

```html
<!-- DocPad Styles + Our Own -->
<%- @getBlock("styles").add(@site.styles).toHTML() %>

<script src="/vendor/modernizr.js"></script>
```

Стало:

```html
<!-- DocPad Styles + Our Own -->
<%- @getBlock("styles").add(@getUrl(@site.styles)).toHTML() %>

<script src="<%= @getUrl('/vendor/modernizr.js') %>"></script>
```

Было:

```html
<ul class="nav-list">
	<li><a href="/"><span>Blog</span></a></li>
	<li><a href="/docs"><span>Documentation</span></a></li>
	<li><a href="https://github.com/paulradzkov/docpad-simpleblog/issues"><span>Issues</span></a></li>
	<li><a href="https://github.com/paulradzkov/docpad-simpleblog"><span>Source Code</span></a></li>
</ul>
```

Стало:

```html
<ul class="nav-list">
	<li><a href="<%= @getUrl('/') %>"><span>Blog</span></a></li>
	<li><a href="<%= @getUrl('/docs') %>"><span>Documentation</span></a></li>
	<li><a href="https://github.com/paulradzkov/docpad-simpleblog/issues"><span>Issues</span></a></li>
	<li><a href="https://github.com/paulradzkov/docpad-simpleblog"><span>Source Code</span></a></li>
</ul>
```

Было:

```html
<ul class="meta-data">
	<li class="comments">
		<a href="<%= @document.path %>#disqus_thread" data-disqus-identifier="<%= @document.disqusid %>" >Комментарии</a>
	</li>
	<li class="tags-list">
		<% for tag in @document.tags : %>
			<a class="label-tag" href="<%= @getTagUrl(tag) %>"><%= tag %></a>
		<% end %>
	</li>
</ul>
```

Стало:

```html
<ul class="meta-data">
	<li class="comments">
		<a href="<%= @getUrl(@document.path) %>#disqus_thread" data-disqus-identifier="<%= @document.disqusid %>" >Комментарии</a>
	</li>
	<li class="tags-list">
		<% for tag in @document.tags : %>
			<a class="label-tag" href="<%= @getUrl(@getTagUrl(tag)) %>"><%= tag %></a>
		<% end %>
	</li>
</ul>
```

И так далее.

Теперь, когда мы запускаем <kbd class="cli" contenteditable="true" >&zwj;<span contenteditable="false">docpad run</span>&zwj;</kbd>, ко всем путям подставляется `@site.url` из девелоперского окружения — `http://localhost:9778`. А когда <kbd class="cli" contenteditable="true" >&zwj;<span contenteditable="false">docpad run --env static</span>&zwj;</kbd>, переменная `@site.url` равна нашему продакшен пути.

## Деплой на GitHub Pages

В репозитории создадим ветку «`gh-pages`». По инструкции это должна быть пустая ветка без истории, но об этом в дальнейшем позаботится плагин для деплоя.

<figure>
	![В репозитории проекта создадим ветку с именем «gh-pages»](new_branch_gh-pages.png)
	<figcaption>В репозитории проекта создадим ветку с именем «`gh-pages`»</figcaption>
</figure>

Установим [GitHub Pages Deployer Plugin for DocPad](https://github.com/docpad/docpad-plugin-ghpages).

При попытке выполнить <kbd class="cli" contenteditable="true">&zwj;<span contenteditable="false">docpad deploy-ghpages --env static</span>&zwj;</kbd> у меня появляется ошибка:

<figure>
	![could not read Username for ’http://github.com’: No such file or directory](gh-pages_deploy_error.png)
	<figcaption>`could not read Username for ’http://github.com’: No such file or directory`</figcaption>
</figure>

Плагин не смог соединиться с моим аккаунтом на гитхабе. Чтобы показать плагину правильный путь с логином и паролем, добавим новый «remote» для репозитория. Для этого в консоли git выполним:

<p><kbd class="cli" contenteditable="true" >&zwj;<span contenteditable="false">git remote add deploy <span>https://</span>login:password@github.com/repo_owner/repo_name.git</span>&zwj;</kbd></p>

Где «`deploy`» — это название удаленного репозитория. Можно выбрать любое, но переопределять «origin» я бы не советовал: у меня от этого локальная копия репозитория потеряла связь с Гитхабом.

«`login`» и «`password`» — данные вашего аккаунта на Гитхабе.

«`github.com/repo_owner/repo_name.git`» — путь к репозиторию проекта, в котором у вас есть права на запись. Это не обязательно должен быть ваш репозиторий, если вы коллаборатор, и у вас есть доступ на запись — вы можете деплоить туда проект.

<figure>
	![Добавление нового «remote» c логином и паролем](adding_another_remote.png)
	<figcaption>Добавление нового «remote» c логином и паролем. Эту процедуру нужно выполнить один раз для каждого локального репозитория</figcaption>
</figure>

А в конфиге докпада пропишем настройки для плагина:

```coffeescript
	# Plugins configurations
	plugins:
		ghpages:
			deployRemote: 'deploy'
			deployBranch: 'gh-pages'
```

Теперь можно выкатывать сайт:

<kbd class="cli" contenteditable="true" >&zwj;<span contenteditable="false">docpad deploy-ghpages --env static</span>&zwj;</kbd>
