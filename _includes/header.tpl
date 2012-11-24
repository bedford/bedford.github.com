<header>
	<h1>{% if page.title %}<a href="/" class="minor">{{ site.name }}</a> / {{ page.title }}{% else %}{{ site.name }}{% endif %}</h1>
	{% if page.title == null %}<p
        class="additional">生活影像记录，工具使用和代码笔记</p>{% endif %}
</header>
