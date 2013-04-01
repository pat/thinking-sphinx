class GyozaTag < Liquid::Tag
  def initialize(tag_name, text, tokens)
    #
  end

  def render(context)
    %Q{<a class="gyoza" href="http://gyozadoc.com/edit/pat/thinking-sphinx#{ context['page']['url'].gsub('.html', '.md') }">Edit via Gyoza</a>}
  end
end

Liquid::Template.register_tag 'gyoza_tag', GyozaTag
