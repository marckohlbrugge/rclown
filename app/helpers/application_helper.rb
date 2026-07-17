module ApplicationHelper
  def page_header(title, &block)
    content_for :header do
      content_tag :div, class: "md:flex md:items-center md:justify-between" do
        content_tag(:h1, title, class: "text-2xl font-bold tracking-tight text-gray-900") +
          (block ? content_tag(:div, capture(&block), class: "mt-4 flex md:ml-4 md:mt-0") : "".html_safe)
      end
    end
  end

  def format_bytes(bytes)
    return "—" unless bytes

    if bytes >= 1_000_000_000
      format("%.2f GB", bytes / 1_000_000_000.0)
    elsif bytes >= 1_000_000
      format("%.2f MB", bytes / 1_000_000.0)
    elsif bytes >= 1_000
      format("%.2f KB", bytes / 1_000.0)
    else
      "#{bytes} B"
    end
  end

  def format_duration(seconds)
    return "—" unless seconds

    hours = (seconds / 3600).floor
    minutes = ((seconds % 3600) / 60).floor
    secs = (seconds % 60).floor

    if hours > 0
      "#{hours}h #{minutes}m"
    elsif minutes > 0
      "#{minutes}m #{secs}s"
    else
      "#{secs}s"
    end
  end
end
