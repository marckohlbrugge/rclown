class TailwindFormBuilder < ActionView::Helpers::FormBuilder
  INPUT_CLASSES = "block w-full rounded-xl border-2 border-gray-200 bg-white px-4 py-3 text-base text-gray-900 placeholder:text-gray-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
  SELECT_CLASSES = "block w-full rounded-xl border-2 border-gray-200 bg-white pl-4 pr-10 py-3.5 text-base text-gray-900 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20"

  %w[text_field url_field email_field number_field password_field telephone_field].each do |method_name|
    define_method(method_name) do |attribute, options = {}|
      options[:class] = merge_classes(INPUT_CLASSES, options[:class])
      super(attribute, options)
    end
  end

  def text_area(attribute, options = {})
    options[:class] = merge_classes(INPUT_CLASSES, options[:class])
    super(attribute, options)
  end

  def select(attribute, choices = nil, options = {}, html_options = {}, &block)
    html_options[:class] = merge_classes(SELECT_CLASSES, html_options[:class])
    super(attribute, choices, options, html_options, &block)
  end

  def collection_select(attribute, collection, value_method, text_method, options = {}, html_options = {})
    html_options[:class] = merge_classes(SELECT_CLASSES, html_options[:class])
    super(attribute, collection, value_method, text_method, options, html_options)
  end

  private

  def merge_classes(*classes)
    classes.compact.join(" ")
  end
end
