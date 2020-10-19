# name: composer-template
# version: 0.1.7
# author: Muhlis Cahyono (muhlisbc@gmail.com)
# url: https://github.com/paviliondev/discourse-rstudio-composer-template-plugin

enabled_site_setting :composer_template_enabled

%i[common desktop mobile].each do |type|
  register_asset "stylesheets/rstudio-composer-template/#{type}.scss", type
end

after_initialize do
  module ::ComposerTemplate
    def self.fields
      [
        {
          'id' => 'description',
          'type' => 'text',
          'placeholder' => 'Description: Short summary of your article. Max 300 char.',
          'regexp' => '^.{0,300}$'
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

        c.sort_order = 'created'
        c.save!
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

    def article_url
      return unless SiteSetting.composer_template_enabled

      category = @topic.category

      return unless category.present?
      return unless category.new_topic_form_enabled?

      @topic.custom_fields.dig('new_topic_form_data', 'url')
    end
  end

  module ::ApplicationHelper
    alias_method :orig_crawlable_meta_data, :crawlable_meta_data

    def crawlable_meta_data(opts = nil)
      opts ||= {}

      if opts[:article_url]
        opts[:url] = opts[:article_url]
        opts[:ignore_canonical] = false
      end

      orig_crawlable_meta_data(opts)
    end
  end

  on(:site_setting_changed) do |site_setting|
    if site_setting == :composer_template_category
      ComposerTemplate.create_form
    end
  end

  on(:category_created) do |_category|
    ComposerTemplate.create_form
  end

  ComposerTemplate.create_form

  add_to_class(:category, :rstudio_topic_previews_enabled?) do
    new_topic_form_enabled? && SiteSetting.composer_template_enabled
  end

  TopicList.preloaded_custom_fields << 'new_topic_form_data'

  add_to_serializer(:topic_list_item, :new_topic_form_data) {
    return unless object.category&.rstudio_topic_previews_enabled?

    object.custom_fields['new_topic_form_data']
  }

  add_to_serializer(:topic_list_item, :op_username) {
    object.user&.username
  }

  %i[topic_list_item topic_view].each do |s|
    add_to_serializer(s, :article_url_host) {
      article_url = new_topic_form_data&.dig('url')

      if article_url
        URI(article_url).host
      end
    }
  end

  add_to_serializer(:basic_category, :rstudio_topic_previews_enabled?) {
    object.rstudio_topic_previews_enabled?
  }

  add_to_serializer(:topic_view, :rstudio_article_url_onebox) {
    article_url = new_topic_form_data&.dig('url')

    if article_url
      Oneboxer.preview(article_url)
    end
  }

  register_svg_icon 'external-link-alt'
end
