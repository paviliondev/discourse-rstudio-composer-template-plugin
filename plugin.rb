# name: composer-template
# version: 0.1.0
# author: Muhlis Cahyono (muhlisbc@gmail.com)

enabled_site_setting :composer_template_enabled

after_initialize do
  module ::ComposerTemplate
    def self.fields
      [
        {
          'id' => 'description',
          'type' => 'text',
          'placeholder' => 'Description: Short summary of your article. Max 300 char.',
          'regexp' => '.{0,300}'
        },
        {
          'id' => 'authors',
          'type' => 'text',
          'placeholder' => 'Authors (Affiliations), e.g. Jon Snow (Royal College of Physicians)'
        },
        {
          'id' => 'url',
          'type' => 'text',
          'placeholder' => 'URL. If report, cite original article'
        },
        {
          'id' => 'article_text',
          'type' => 'textarea',
          'required' => true
        }
      ]
    end

    def self.create_form
      PluginStoreRow.where(plugin_name: 'new_topic_form').delete_all

      category = Category.find_by(id: SiteSetting.composer_template_category)

      return if category.blank?

      create_form_for = ->(c) do
        topic_form = NewTopicForm::Form.new(c)

        topic_form.form['enabled'] = true
        topic_form.form['fields'] = fields

        topic_form.save
      end

      create_form_for.call(category)

      category.subcategories.each do |subcategory|
        create_form_for.call(subcategory)
      end
    end
  end

  ApplicationController.prepend_view_path File.expand_path('../views', __FILE__)

  class ::TopicView
    def og_description
      smr = summary(strip_images: true)

      return smr unless SiteSetting.composer_template_enabled

      category = @topic.category

      return smr unless category.present?
      return smr unless category.new_topic_form_enabled?

      desc = @topic.custom_fields.dig('new_topic_form_data', 'description')

      return smr if desc.blank?

      desc
    end
  end

  on(:site_setting_changed) do |site_setting|
    if site_setting == :composer_template_category
      ComposerTemplate.create_form
    end
  end

  ComposerTemplate.create_form
end
