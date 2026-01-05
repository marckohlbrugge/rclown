class FormBuilder < ActionView::Helpers::FormBuilder
  INPUT_CLASSES = "form-input"

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
    html_options[:class] = merge_classes(INPUT_CLASSES, html_options[:class])
    super(attribute, choices, options, html_options, &block)
  end

  def collection_select(attribute, collection, value_method, text_method, options = {}, html_options = {})
    html_options[:class] = merge_classes(INPUT_CLASSES, html_options[:class])
    super(attribute, collection, value_method, text_method, options, html_options)
  end

  private

  def merge_classes(*classes)
    classes.compact.join(" ")
  end
end
