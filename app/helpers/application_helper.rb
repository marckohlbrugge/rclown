module ApplicationHelper
  def nav_link_classes(active)
    base = "inline-flex items-center border-b-2 px-1 pt-1 text-sm font-medium"
    if active
      "#{base} border-blue-500 text-gray-900"
    else
      "#{base} border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700"
    end
  end

  def mobile_nav_link_classes(active)
    base = "block rounded-md px-3 py-2 text-base font-medium"
    if active
      "#{base} bg-blue-50 text-blue-700"
    else
      "#{base} text-gray-600 hover:bg-gray-50 hover:text-gray-900"
    end
  end

  def page_header(title, &block)
    content_for :header do
      content_tag :div, class: "md:flex md:items-center md:justify-between" do
        content_tag(:h1, title, class: "text-2xl font-bold tracking-tight text-gray-900") +
          (block ? content_tag(:div, capture(&block), class: "mt-4 flex md:ml-4 md:mt-0") : "".html_safe)
      end
    end
  end
end
