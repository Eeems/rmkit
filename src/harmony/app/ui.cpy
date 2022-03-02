#include <ctime>
#include "brush.h"
#include "canvas.h"
#include "dialogs.h"
#include "state.h"

#define DIALOG_WIDTH 600
#define DIALOG_HEIGHT 500
#define LOAD_DIALOG_HEIGHT 1000
namespace app_ui:

  class ToolButton: public ui::TextDropdown:
    public:
    ToolButton(int x, int y, int w, int h): \
               ui::TextDropdown(x, y, w, h, "tools"):

      ds := self.add_section("brushes")
      for auto b : brush::NP_BRUSHES:
        ds->add_options({make_pair(b->name, b->icon)})

      ds = self.add_section("procedural")
      for auto b : brush::P_BRUSHES:
        ds->add_options({make_pair(b->name, b->icon)})

      ds = self.add_section("erasers")
      for auto b : brush::ERASERS:
        ds->add_options({make_pair(b->name, b->icon)})

      self.select(0)

    void on_select(int idx):
      name := self.options[idx]->name
      for auto b : brush::P_BRUSHES:
        if b->name == name:
          STATE.brush = b
      for auto b : brush::ERASERS:
        if b->name == name:
          STATE.brush = b
      for auto b : brush::NP_BRUSHES:
        if b->name == name:
          STATE.brush = b
      self.text = ""


  class BrushConfigButton: public ui::TextDropdown:
    public:
    BrushConfigButton(int x, y, w, h): \
      ui::TextDropdown(x,y,w,h,"brush config"):
      ds := self.add_section("size")
      for auto b : stroke::SIZES:
        ds->add_options({b->name})

      ds = add_section("color")
      ds->add_options({"black", "gray1", "gray2", "gray3", "gray4", "white"})

    void on_select(int i):
      option := self.options[i]->name
      do {
        if option == stroke::FINE.name:
          STATE.stroke_width = stroke::FINE.val
          break
        if option == stroke::MEDIUM.name:
          STATE.stroke_width = stroke::MEDIUM.val
          break
        if option == stroke::WIDE.name:
          STATE.stroke_width = stroke::WIDE.val
          break

        if option == "black":
          STATE.color = BLACK
          break
        if option == "white":
          STATE.color = WHITE
          break
        if option == "gray1":
          STATE.color = color::GRAY_3
          break
        if option == "gray2":
          STATE.color = color::GRAY_6
          break
        if option == "gray3":
          STATE.color = color::GRAY_9
          break
        if option == "gray4":
          STATE.color = color::GRAY_12
          break
      } while(false);

      self.before_render()

    void render():
      sw := 1
      for auto size : stroke::SIZES:
        if STATE.stroke_width == size->val:
          sw = (size->val+1) * 5
          break

      color := STATE.color
      bg_color := color == WHITE ? BLACK : WHITE

      self.fb->draw_rect(self.x, self.y, self.w, self.h, WHITE, true)

      if self.mouse_inside:
        self.fb->draw_rect(self.x, self.y, self.w, self.h, BLACK, false)

      mid_y := (self.h - sw) / 2

      self.fb->draw_line(self.x+3, self.y+mid_y-2, self.x+self.w-sw-3, self.y+mid_y-2, sw+4, bg_color)
      self.fb->draw_line(self.x+5, self.y+mid_y, self.x+self.w-sw-5, self.y+mid_y, sw, color)

  class LiftBrushButton: public ui::Button:
    public:
    Canvas *canvas
    LiftBrushButton(int x, int y, int w, int h, Canvas *c): \
        ui::Button(x,y,w,h,"lift"):
      self.canvas = c

    void on_mouse_click(input::SynMotionEvent &ev):
      self.dirty = 1
      self.canvas->curr_brush->reset()

    void before_render():
      f := std::find(brush::P_BRUSHES.begin(), brush::P_BRUSHES.end(), \
                     self.canvas->curr_brush)
      self.visible = f != brush::P_BRUSHES.end()
      ui::Button::before_render()

    void render():
      self->fb->draw_rect(self.x, self.y, self.w, self.h, WHITE, true)
      ui::Button::render()
      self->fb->draw_rect(self.x, self.y, self.w, self.h, BLACK, false)
      if self.mouse_down:
        self->fb->draw_rect(self.x, self.y, self.w, self.h, BLACK, true)
      else if self.mouse_inside:
          self->fb->draw_rect(self.x, self.y, self.w, self.h, GRAY, false)

  string  ABOUT = "about",\
          CLEAR = "new",\
          DOTS  = "...",\
          QUIT  = "exit",\
          SAVE  = "save",\
          LOAD  = "load",\
          EXPORT = "export",\
          IMPORT = "import"
  class ManageButton: public ui::TextDropdown:
    public:
    Canvas *canvas

    AboutDialog *ad = NULL
    ExitDialog *ed = NULL
    SaveDialog *sd = NULL
    LoadDialog *ld = NULL

    ManageButton(int x, y, w, h, Canvas *c): TextDropdown(x,y,w,h,"...")
      self.canvas = c
      ds := self.add_section("")
      ds->add_options({QUIT, DOTS, CLEAR, SAVE, LOAD, DOTS, EXPORT, IMPORT, DOTS, ABOUT})
      self.text = "..."

    void select_exit():
      if self.ed == NULL:
        self.ed = new ExitDialog(0, 0, DIALOG_WIDTH, DIALOG_HEIGHT)
      self.ed->show()
    void on_select(int i):
      option := self.options[i]->name
      if option == ABOUT:
        if self.ad == NULL:
          self.ad = new AboutDialog(0, 0, DIALOG_WIDTH, DIALOG_HEIGHT)
        self.ad->show()
      if option == CLEAR:
        self.canvas->reset()
      if option == QUIT:
        self.select_exit()
      if option == EXPORT:
        filename := self.canvas->save_png()
        if self.sd == NULL:
          self.sd = new SaveDialog(0, 0, DIALOG_WIDTH*2, DIALOG_HEIGHT)
        title := "Saved as " + filename
        self.sd->set_title(title)
        self.sd->show()
      if option == IMPORT:
        if self.ld == NULL:
          self.ld = new LoadDialog(0, 0, DIALOG_WIDTH, LOAD_DIALOG_HEIGHT, self.canvas)
        self.ld->populate()
        self.ld->setup_for_render()
        self.ld->show()

      self.text = "..."

  class HistoryButton: public ui::Button:
    public:
    Canvas *canvas
    HistoryButton(int x, y, w, h, Canvas *c): ui::Button(x,y,w,h,"history"):
      self.canvas = c
      self.text = "history"

    void on_mouse_click(input::SynMotionEvent &ev):
      self.dirty = 1
      STATE.disable_history = !STATE.disable_history

    void render():
      ui::Button::render()
      if STATE.disable_history:
        self.fb->draw_line(self.x, self.y, self.w+self.x, self.h+self.y, 4, BLACK)

  class UndoButton: public ui::Button:
    public:
    Canvas *canvas
    UndoButton(int x, y, w, h, Canvas *c): ui::Button(x,y,w,h,"undo"):
      self.canvas = c
      self.icon = ICON(assets::icons_fa_arrow_left_solid_png)
      self.text = ""

    void render():
      if self.canvas->layers[canvas->cur_layer].undo_stack.size() > 1:
        ui::Button::render()

    void on_mouse_click(input::SynMotionEvent &ev):
      self.dirty = 1
      self.canvas->undo()

  class PalmButton: public ui::Button:
    public:
    PalmButton(int x, y, w, h): ui::Button(x,y,w,h,"reject palm"):
      self.icon = ICON(assets::icons_fa_hand_paper_solid_png)
      self.text = ""

    void render():
      ui::Button::render()
      if STATE.reject_touch:
        self.fb->draw_line(self.x, self.y, self.w+self.x, self.h+self.y, 4, BLACK)

    void on_mouse_click(input::SynMotionEvent &ev):
      STATE.reject_touch = !STATE.reject_touch
      self.dirty = 1

  class RedoButton: public ui::Button:
    public:
    Canvas *canvas
    RedoButton(int x, y, w, h, Canvas *c): ui::Button(x,y,w,h,"redo"):
      self.canvas = c
      self.icon = ICON(assets::icons_fa_arrow_right_solid_png)
      self.text = ""

    void render():
      if self.canvas->layers[canvas->cur_layer].redo_stack.size():
        ui::Button::render()

    void on_mouse_click(input::SynMotionEvent &ev):
      self.dirty = 1
      self.canvas->redo()

  class LayerDialog: public ui::Pager:
    public:
    Canvas *canvas

    LayerDialog(int x, y, w, h, Canvas* c): ui::Pager(x, y, w, h, self):
      self.set_title("")
      self.canvas = c
      self.opt_h = 55
      self.page_size = (self.h - 100) / self.opt_h
      self.buttons = {"New Layer"}


    void on_row_selected(string name):
      debug "ROW SELECTED", name
      canvas->select_layer(get_layer(name))
      ui::MainLoop::hide_overlay()

    void populate_and_show():
      self.populate()
      self.setup_for_render()
      self.show()

    void on_button_selected(string name):
      debug "Button Selected:", name
      if name.find("Layer") == 0:
        on_row_selected(name)

      if name == "New Layer":
        debug "Adding New Layer"
        canvas->new_layer(true)
        self.populate_and_show()


    string layer_name(int i):
      return "Layer " + to_string(i)

    int get_layer(string name):
      tokens := str_utils::split(name, ' ')
      return atoi(tokens[1].c_str())

    void populate():
      self.options.clear()
      for int i = canvas->layers.size()-1; i >= 0; i--:
        options.push_back(layer_name(i))

    void add_buttons(ui::HorizontalLayout *button_bar):
      // Skip the pager buttons
      ui::Dialog::add_buttons(button_bar)

    string visible_icon(int i):
      return canvas->is_layer_visible(i) ? "V" : "H"

    void render_row(ui::HorizontalLayout *row, string option):
      self.layout->pack_start(row)
      layer_id := get_layer(option)
      bw := 150
      offset := 0

      debug "RENDERING ROW", option
      style := ui::Stylesheet().justify_left().valign_middle()

      // make a button for each of the following: toggle visible,
      // delete, merge down, clear
      visible_button := new ui::Button(0, 0, 50, self.opt_h, visible_icon(layer_id))
      visible_button->mouse.click += PLS_LAMBDA(auto &ev):
        debug "Visible Button Clicked"
        canvas->toggle_layer(layer_id)
        visible_button->text = visible_icon(layer_id)
      ;
      offset += 50
      visible_button->set_style(style.justify_center())

      delete_button := new ui::Button(0, 0, bw, self.opt_h, "Delete")
      delete_button->mouse.click += PLS_LAMBDA(auto &ev):
        debug "Delete Button Clicked"
        canvas->delete_layer(layer_id)
        self.populate_and_show()
      ;
      offset += bw
      delete_button->set_style(style.justify_center())

//      merge_button := new ui::Button(0, 0, bw, self.opt_h, "Merge")
//      merge_button->mouse.click += PLS_LAMBDA(auto &ev):
//        debug "Merge Button Clicked"
//      ;
//      merge_button->set_style(style.justify_center())
//      offset += bw

      // Layer Button
      d := new ui::DialogButton(0, 0, self.w - (offset + 10), self.opt_h, self, option)
      d->x_padding = 10
      d->y_padding = 5
      if option == layer_name(canvas->cur_layer):
        d->set_style(style.border_left())
      else:
        d->set_style(style)


      row->pack_start(visible_button)
      row->pack_start(d)
      row->pack_end(delete_button)
      // row->pack_end(merge_button)

  class LayerButton: public ui::Button:
    public:
    Canvas *canvas
    LayerDialog *ld

    LayerButton(int x, y, w, h, Canvas *c): ui::Button(x,y,w,h,"...")
      self.canvas = c
      self.ld = new LayerDialog(0, 0, 800, 600, c)

    void on_mouse_click(input::SynMotionEvent &ev):
      self.ld->populate_and_show()

    void before_render():
      if canvas->layers[canvas->cur_layer].visible:
      text = "Layer " + to_string(canvas->cur_layer)
      ui::Button::before_render()

    void render():
      ui::Button::render()
      if !canvas->layers[canvas->cur_layer].visible:
        fb->draw_line(x, y, x+w, y+h, 4, BLACK)


  class HideButton: public ui::Button:
    public:
    ui::Layout *toolbar, *minibar
    HideButton(int x, y, w, h, ui::Layout *l, *m): ui::Button(x,y,w,h,"v"):
      self.toolbar = l
      self.minibar = m

    void on_mouse_click(input::SynMotionEvent &ev):
      self.dirty = 1

      if self.toolbar->visible:
        self.toolbar->hide()
        self.minibar->show()
      else:
        self.toolbar->show()
        self.minibar->hide()

      ui::MainLoop::full_refresh()

    void render():
      self.text = self.toolbar->visible ? "v" : "^"
      ui::Button::render()

  class Clock: public ui::Text:
    public:
    Clock(int x, y, w, h): Text(x,y,w,h,"clock"):
      self.set_style(ui::Stylesheet().justify_center())

    void before_render():
      time_t rawtime;
      struct tm * timeinfo;
      char buffer[80];

      time (&rawtime);
      timeinfo = localtime(&rawtime);

      strftime(buffer,sizeof(buffer),"%H:%M ",timeinfo);
      self.text = std::string(buffer)
