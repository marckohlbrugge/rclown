module ApplicationHelper
  def page_header(title, &block)
    content_for :header do
      content_tag :div, class: "md:flex md:items-center md:justify-between" do
        content_tag(:h1, title, class: "text-2xl font-bold tracking-tight text-gray-900") +
          (block ? content_tag(:div, capture(&block), class: "mt-4 flex md:ml-4 md:mt-0") : "".html_safe)
      end
    end
  end
end
