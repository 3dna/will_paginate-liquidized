require 'will_paginate/view_helpers'
require 'will_paginate/view_helpers/link_renderer'

module WillPaginate::Liquidized
  module ViewHelpers

    include WillPaginate::ViewHelpers

    def will_paginate_liquid(collection, anchor = nil, prev_label = nil, next_label = nil)
      opts = {}
      opts[:previous_label] = prev_label if prev_label
      opts[:next_label]     = next_label if next_label
      opts[:params]         = {:anchor => anchor} if anchor
      opts[:controller]     = @context.registers[:controller]

      with_renderer 'WillPaginate::Liquidized::LinkRenderer' do
        will_paginate *[collection, opts].compact
      end
    end

    alias_method :paginate, :will_paginate_liquid

    def with_renderer(renderer)
      old_renderer, options[:renderer] = options[:renderer], renderer
      result = yield
      options[:renderer] = old_renderer
      result
    end

    def options
      WillPaginate::ViewHelpers.pagination_options
    end

    def page_entries_info(collection, options = {})
      entry_name = options[:model] ||
        (collection.empty?? 'entry' : collection.first.class.name.underscore.sub('_', ' '))

      if collection.total_pages < 2
        case collection.size
          when 0; "No #{entry_name.pluralize} found"
          when 1; "<b>1</b> #{entry_name}"
          else;   "<b>All #{collection.size}</b> #{entry_name.pluralize}"
        end
      else
        %{<b>%d&nbsp;-&nbsp;%d</b> of <b>%d</b> #{entry_name.pluralize}} % [
          collection.offset + 1,
          collection.offset + collection.length,
          collection.total_entries
        ]
      end.html_safe
    end
  end

  class LinkRenderer < WillPaginate::ViewHelpers::LinkRenderer

    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TagHelper


    def to_html
      return "<p><strong style=\"color:red;\">(Will Paginate Liquidized) Error:</strong> you must pass a controller in Liquid render call; <br/>
              e.g. Liquid::Template.parse(\"{{ movies | will_paginate_liquid }}\").render({'movies' => @movies}, :registers => {:controller => @controller})</p>" unless @options[:controller]

      links = []
      # previous/next buttons added in to the links collection
      links.unshift page_link(@collection.previous_page, @options[:previous_label].html_safe) if @collection.previous_page
      links.push    page_link(@collection.next_page, @options[:next_label].html_safe) if @collection.next_page
      html = links.join(@options[:separator] || "&nbsp;&nbsp;".html_safe)
      html_attributes ||= {}
      html_attributes.delete(:controller)
      @options[:container] ? content_tag(:div, html.html_safe, html_attributes).html_safe : html.html_safe
    end

    def page_link(page, text, attributes = {})
      link_to text, url_for_page(page), attributes
    end

    def page_span(page, text, attributes = {})
      content_tag :span, text, attributes
    end

    def url_for_page(page)
      page_one = page == 1
      unless @url_string and !page_one
        @url_params = {}
        @controller = @options[:controller]
        # page links should preserve GET parameters
        stringified_merge @url_params, @controller.params if @controller && @controller.request.get? && @controller.params
        stringified_merge @url_params, @options[:params] if @options[:params]

        if complex = param_name.index(/[^\w-]/)
          page_param = (defined?(CGIMethods) ? CGIMethods : ActionController::AbstractRequest).
            parse_query_parameters("#{param_name}=#{page}")

          stringified_merge @url_params, page_param
        else
          @url_params[param_name] = page_one ? 1 : 2
        end

        url = @controller.url_for(@url_params)
        url = "#{url}##{@options[:params][:anchor]}" if @options[:params] && @options[:params][:anchor]
        return url if page_one

        if complex
          @url_string = url.sub(%r!((?:\?|&amp;)#{CGI.escape param_name}=)#{page}!, '\1@')
          return url
        else
          @url_string = url
          @url_params[param_name] = 3
          @controller.url_for(@url_params).split(//).each_with_index do |char, i|
            if char == '3' and url[i, 1] == '2'
              @url_string[i] = '@'
              break
            end
          end
        end
      end
      # finally!
      @url_string.sub '@', page.to_s
    end

    def stringified_merge(target, other)
      other.each do |key, value|
        key = key.to_s
        existing = target[key]

        if (value.is_a?(Hash) || value.is_a?(HashWithIndifferentAccess)) && (!existing || existing.is_a?(HashWithIndifferentAccess))
          target[key] = existing || HashWithIndifferentAccess.new
          stringified_merge(target[key], value)
        else
          target[key] = value
        end
      end
    end
  end
end
