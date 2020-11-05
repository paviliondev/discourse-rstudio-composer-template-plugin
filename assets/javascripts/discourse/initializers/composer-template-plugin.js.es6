import { withPluginApi } from "discourse/lib/plugin-api";
import discourseComputed from "discourse-common/utils/decorators";
import { inject } from "@ember/controller";
import getURL from "discourse-common/lib/get-url";
import Category from "discourse/models/category";
import I18n from "I18n";

function initWithApi(api) {
  if (!Discourse.SiteSettings.composer_template_enabled) return;

  api.modifyClass("controller:composer", {
    @discourseComputed(
      "model.action",
      "isWhispering",
      "model.editConflict",
      "model.showFields"
    )
    saveLabel(modelAction, isWhispering, editConflict, showFields) {
      if (!showFields) return this._super(...arguments);

      return "composer_template.submit_article";
    },

    ntfCreateReply() {
      return;
    },

    ntfOriginalValidation() {
      if (this.disableSubmit) return;

      if (!this.showWarning) {
        this.set("model.isWarning", false);
      }

      if (this.model.cantSubmitPost) {
        this.set("lastValidatedAt", Date.now());
        return;
      }
    },

    save(force) {
      if (this.get("model.showFields")) {
        this.ntfOriginalValidation();
      }

      this._super(...arguments);
    },
  });

  api.modifyClass("component:topic-list-item", {
    categoryCtrl: inject("navigation/category")
  });

  api.decorateWidget("header-icons:before", (dec) => {
    const newsCatId = parseInt(dec.widget.siteSettings.composer_template_category.split('|')[0]);
    const jobsCatId = parseInt(dec.widget.siteSettings.rstudio_jobs_category.split('|')[0]);

    let result = [];
    
    if (jobsCatId > 0) {
      const jobsCategory = dec.widget.site.categories.findBy("id", jobsCatId);
      result.push(dec.h("li.rstudio-jobs-category-link", dec.h("a", {
        href: getURL(`/c/${Category.slugFor(jobsCategory)}/${jobsCategory.get("id")}`)
      }, I18n.t("rstudio_header_links.jobs"))));
    }

    if (newsCatId > 0) {
      const newsCategory = dec.widget.site.categories.findBy("id", newsCatId);
      result.push(dec.h("li.rstudio-news-category-link", dec.h("a", {
        href: getURL(`/c/${Category.slugFor(newsCategory)}/${newsCategory.get("id")}`)
      }, I18n.t("rstudio_header_links.news"))));
    }

    return dec.h('ul.rstudio-links', result);
  });
  
  const categoryRoutes = [
    'category',
    'parentCategory',
    'categoryNone',
    'categoryWithID'
  ];
  
  categoryRoutes.forEach(function(route){
    api.modifyClass(`route:discovery.${route}`, {
      filter(category) {
        if (this.siteSettings.composer_template_category.split('|').includes(category.id.toString())) {
          return "articles";
        } else {
          return this._super(category);
        }
      },
    });
  });
}

export default {
  name: "composer-template-plugin",
  after: "new-topic-form",
  initialize() {
    withPluginApi("0.8", initWithApi);
  },
};
