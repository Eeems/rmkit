#include <dirent.h>
#include <algorithm>

string ABOUT_TEXT = "\
rmHarmony is a sketching app based on libremarkable and mr. doob's harmony. \
brought to you by the letters N and O. icons are from fontawesome \n\n\
source available at https://github.com/rmkit-dev/rmKit \n \
"
namespace app_ui:
  class AboutDialog: public ui::InfoDialog:
    public:
      AboutDialog(int x, y, w, h): ui::InfoDialog(x, y, w, h):
        self.set_title("About")
        self.contentWidget = \
          new ui::MultiText(20, 20, self.w, self.h - 100, ABOUT_TEXT)

  class ExitDialog: public ui::ConfirmationDialog:
    public:
      ExitDialog(int x, y, w, h): ui::ConfirmationDialog(x, y, w, h):
        self.set_title("Exit?")

      void on_button_selected(string t):
        if t == "OK":
          exit(0)
        if t == "CANCEL":
          ui::MainLoop::hide_overlay()

  class ExportDialog: public ui::InfoDialog:
    public:
      ExportDialog(int x, y, w, h): ui::InfoDialog(x, y, w, h):
        pass

  class SaveProjectDialog: public ui::ConfirmationDialog:
    public:
      Canvas *canvas
      ui::TextInput *projectInput
      SaveProjectDialog(int x, y, w, h, Canvas *c): ui::ConfirmationDialog(x, y, w, h):
        canvas = c
        self.set_title("Save project as")
        style := ui::Stylesheet().justify_left().valign_middle()
        self.projectInput = \
          new ui::TextInput(20, 20, self.w - 40, 50, "Untitled")
        self.projectInput->set_style(style)
        self.contentWidget = self.projectInput

      void on_button_selected(string t):
        debug "BUTTON SELECTED", t, self.projectInput->text
        ui::MainLoop::hide_overlay()



  class ImportDialog: public ui::Pager:
    public:
      Canvas *canvas

      ImportDialog(int x, y, w, h, Canvas *c): ui::Pager(x, y, w, h, self):
        self.set_title("Select a png file...")

        self.canvas = c
        self.opt_h = 187
        self.page_size = self.h / self.opt_h - 1

      void populate():
        DIR *dir
        struct dirent *ent

        vector<string> filenames
        if ((dir = opendir (SAVE_DIR)) != NULL):
          while ((ent = readdir (dir)) != NULL):
            str_d_name := string(ent->d_name)
            if str_d_name != "." and str_d_name != ".." and ends_with(str_d_name, "png"):
              filenames.push_back(str_d_name)
          closedir (dir)
        else:
          perror ("")
        sort(filenames.begin(),filenames.end())
        self.options = filenames

      void on_row_selected(string name):
        self.canvas->load_from_png(name)
        ui::MainLoop::hide_overlay()

      void render_row(ui::HorizontalLayout *row, string option):
        char full_path[PATH_MAX]
        sprintf(full_path, "%s/%s", SAVE_DIR, option.c_str())

        ui::Thumbnail *tn = new ui::Thumbnail(0, 0, 140, self.opt_h, full_path)
        d := new ui::DialogButton(20, 0, self.w-200, self.opt_h, self, option)
        layout->pack_start(row)
        row->pack_start(tn)
        row->pack_start(d)

  class LoadProjectDialog: public ui::Pager:
    public:
      LoadProjectDialog(int x, y, w, h, Canvas *c): ui::Pager(x, y, w, h, self):
        self.set_title("Load Project")

      void on_row_selected(string name):
        // self.canvas->load_project(name)
        debug "LOADING PROJECT"

      void populate():
        DIR *dir
        struct dirent *ent

        vector<string> filenames
        if ((dir = opendir (SAVE_DIR)) != NULL):
          while ((ent = readdir (dir)) != NULL):
            str_d_name := string(ent->d_name)
            if str_d_name != "." and str_d_name != ".." and ends_with(str_d_name, "hrm"):
              filenames.push_back(str_d_name)
          closedir (dir)
        else:
          perror ("")
        sort(filenames.begin(),filenames.end())
        self.options = filenames

