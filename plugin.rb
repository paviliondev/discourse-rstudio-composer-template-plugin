# name: composer-template
# version: 0.1.8
# author: Muhlis Cahyono (muhlisbc@gmail.com)
# url: https://github.com/paviliondev/discourse-rstudio-composer-template-plugin

enabled_site_setting :rstudio_composer_template_enabled

%i[common desktop mobile].each do |type|
  register_asset "stylesheets/rstudio-composer-template/#{type}.scss", type
end

Discourse.filters.push :articles
Discourse.anonymous_filters.push :articles

after_initialize do
  %w[
    ../lib/composer_template/engine.rb
    ../controllers/composer_template/admin_controller.rb
    ../config/routes.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end
  
  module ::ComposerTemplate
    def self.news_fields
      [
        {
          'id' => 'description',
          'type' => 'text',
          'placeholder' => 'Description: Short summary of your article. Max 300 char.'
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
          'id' => 'image_url',
          'type' => 'text',
          'placeholder' => 'Image URL. What will display in the topic list.'
        },
        {
          'id' => 'posted_at',
          'type' => 'date',
          'placeholder' => 'Date article was posted.'
        }
      ]
    end

    def self.gallery_fields
      [
        {
          'id' => 'description',
          'type' => 'text',
          'placeholder' => 'Description: Short summary of your table. Max 500 char.'
        },
        {
          'id' => 'authors',
          'type' => 'text',
          'placeholder' => 'Authors (Affiliations), e.g. Jon Snow (Royal College of Physicians)'
        },
        {
          'id' => 'image_url',
          'type' => 'text',
          'placeholder' => 'Image URL. What will display in the topic list.'
        },
      ]
    end

    def self.create_news_form
      PluginStoreRow.where(plugin_name: 'new_topic_form').delete_all

      categories = Category.where(id: SiteSetting.rstudio_composer_template_category.split('|')).to_a

      return if categories.blank?
      
      categories.each do |category|
        create_form_for = ->(c) do
          topic_form = NewTopicForm::Form.new(c)

          topic_form.form['enabled'] = true
          topic_form.form['fields'] = news_fields

          topic_form.save
        end

        create_form_for.call(category)

        category.subcategories.each do |subcategory|
          create_form_for.call(subcategory)
        end
      end
    end

    def self.create_gallery_form
      PluginStoreRow.where(plugin_name: 'new_topic_form').delete_all

      categories = Category.where(id: SiteSetting.rstudio_composer_gallery_template_category.split('|')).to_a

      return if categories.blank?
      
      categories.each do |category|
        create_form_for = ->(c) do
          topic_form = NewTopicForm::Form.new(c)

          topic_form.form['enabled'] = true
          topic_form.form['fields'] = gallery_fields

          topic_form.save
        end

        create_form_for.call(category)

        category.subcategories.each do |subcategory|
          create_form_for.call(subcategory)
        end
      end
    end
  end

  ApplicationController.prepend_view_path File.expand_path('../views', __FILE__)

  class ::TopicView
    def og_description
      smr = summary(strip_images: true)

      return smr unless SiteSetting.rstudio_composer_template_enabled

      category = @topic.category

      return smr unless category.present?
      return smr unless category.new_topic_form_enabled?

      desc = @topic.custom_fields.dig('new_topic_form_data', 'description')

      return smr if desc.blank?

      desc
    end

    def article_url
      return unless SiteSetting.rstudio_composer_template_enabled

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
    if site_setting == :rstudio_composer_template_category
      ComposerTemplate.create_news_form
    end
    if site_setting == :rstudio_composer_gallery_template_category
      ComposerTemplate.create_gallery_form
    end
  end

  on(:category_created) do |_category|
    ComposerTemplate.create_news_form
    ComposerTemplate.create_gallery_form
  end

  ComposerTemplate.create_news_form
  ComposerTemplate.create_gallery_form

  add_to_class(:category, :rstudio_topic_previews_enabled?) do
    new_topic_form_enabled? && SiteSetting.rstudio_composer_template_enabled
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

  register_svg_icon 'external-link-alt'
  
  add_to_class(:topic_query, :list_articles) do
    create_list(:articles, unordered: true) do |topics|
      topics.joins("
        INNER JOIN topic_custom_fields as tcf
        ON tcf.topic_id = topics.id
        AND tcf.name = 'new_topic_form_data'
      ").reorder("tcf.value::json->>'posted_at' DESC")
    end
  end
  
  on(:new_topic_form_before_save) do |form_data|
    if form_data['posted_at'] && (match = form_data['posted_at'].match(/date=(\S+)/i))
      form_data['posted_at'] = match.captures.first
    end
  end
end
