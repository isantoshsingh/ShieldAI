module ApplicationHelper
  def pagy_nav(pagy)
    return "" unless pagy.pages > 1

    html = '<nav class="flex items-center justify-center space-x-1 mt-4">'
    if pagy.prev
      html += link_to("Previous", request.params.merge(page: pagy.prev), class: "px-3 py-1 text-sm rounded border border-gray-300 hover:bg-gray-50")
    end
    (1..pagy.pages).each do |page|
      if page == pagy.page
        html += content_tag(:span, page, class: "px-3 py-1 text-sm rounded bg-indigo-600 text-white")
      else
        html += link_to(page, request.params.merge(page: page), class: "px-3 py-1 text-sm rounded border border-gray-300 hover:bg-gray-50")
      end
    end
    if pagy.next
      html += link_to("Next", request.params.merge(page: pagy.next), class: "px-3 py-1 text-sm rounded border border-gray-300 hover:bg-gray-50")
    end
    html += '</nav>'
    html.html_safe
  end
end
