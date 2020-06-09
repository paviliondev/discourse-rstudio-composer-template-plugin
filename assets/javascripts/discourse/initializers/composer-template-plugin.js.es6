import { withPluginApi } from "discourse/lib/plugin-api";
import discourseComputed from "discourse-common/utils/decorators";
import { inject } from "@ember/controller";
import getURL from "discourse-common/lib/get-url";
import Category from "discourse/models/category";

function initWithApi(api) {
  if (!Discourse.SiteSettings.composer_template_enabled) return;

  api.modifyClass("controller:composer", {
    @discourseComputed("model.action", "isWhispering", "model.editConflict", "model.showFields")
    saveLabel(modelAction, isWhispering, editConflict, showFields) {
      if (!showFields) return this._super(...arguments);

      return "composer_template.submit_article";
    },

    ntfCreateReply() {
      return;
    }
  });

  api.modifyClass("component:topic-list-item", {
    categoryCtrl: inject("navigation/category"),
  });

  api.decorateWidget("header-icons:before", dec => {
    const catId = parseInt(dec.widget.siteSettings.composer_template_category);
    const category = dec.widget.site.categories.findBy("id", catId);

    if (!category) return;

    const link = dec.h("a", {
      href: getURL(`/c/${Category.slugFor(category)}/${category.get("id")}`)
    }, "News");

    return dec.h("li.rstudio-news-category-link", link);
  });

  api.decorateWidget("post-contents:after-cooked", dec => {
    const model = dec.getModel();

    if (!model.firstPost) return;
    if (!model.topic.category.rstudio_topic_previews_enabled) return;

    const onebox = model.topic.rstudio_article_url_onebox;

    if (onebox) {
      return dec.rawHtml(onebox);
    }
  });
}

export default {
  name: "composer-template-plugin",
  after: "new-topic-form",
  initialize() {
    withPluginApi("0.8", initWithApi);
  }
};
