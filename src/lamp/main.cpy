#include <linux/input.h>
#include <string>
#include <vector>

#include <unistd.h>
#include <sys/types.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sstream>
#include <math.h>

#include "../rmkit/input/device_id.h"
#include "../rmkit/util/machine_id.h"
#include "../rmkit/defines.h"
#include "../shared/string.h"
using namespace std

int offset = 0
int move_pts = 500


rm_version := util::get_remarkable_version()

int get_pen_x(int x):
  return x / WACOM_X_SCALAR

int get_pen_y(int y):
  return WACOMHEIGHT - (y / WACOM_Y_SCALAR)

int get_touch_x(int x):
  if rm_version == util::RM_VERSION::RM2:
    return x
  return (MTWIDTH - x) / MT_X_SCALAR

int get_touch_y(int y):
  if rm_version == util::RM_VERSION::RM2:
    return DISPLAYHEIGHT - y
  return (MTHEIGHT - y) / MT_Y_SCALAR

vector<input_event> finger_clear():
  vector<input_event> ev
  ev.push_back(input_event{ type:EV_ABS, code:ABS_MT_TRACKING_ID, value: -1 })
  ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value: 1 })
  return ev

vector<input_event> finger_down(int x, y):
  vector<input_event> ev

  now := time(NULL) + offset++
  ev.push_back(input_event{ type:EV_ABS, code:ABS_MT_TRACKING_ID, value: now })
  ev.push_back(input_event{ type:EV_ABS, code:ABS_MT_POSITION_X, value: get_touch_x(x) })
  ev.push_back(input_event{ type:EV_ABS, code:ABS_MT_POSITION_Y, value: get_touch_y(y) })
  ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })
  return ev

vector<input_event> finger_move(int ox, oy, x, y, points=10):
  ev := finger_down(ox, oy)
  double dx = float(x - ox) / float(points)
  double dy = float(y - oy) / float(points)

  for int i = 0; i <= points; i++:
    ev.push_back(input_event{ type:EV_ABS, code:ABS_MT_POSITION_X, value: get_touch_x(ox + (i*dx)) })
    ev.push_back(input_event{ type:EV_ABS, code:ABS_MT_POSITION_Y, value: get_touch_y(oy + (i*dy)) })
    ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })

  return ev

vector<input_event> finger_up()
  vector<input_event> ev
  ev.push_back(input_event{ type:EV_ABS, code:ABS_MT_TRACKING_ID, value: -1 })
  ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })
  return ev

vector<input_event> pen_clear():
  vector<input_event> ev
  ev.push_back(input_event{ type:EV_ABS, code:ABS_X, value: -1 })
  ev.push_back(input_event{ type:EV_ABS, code:ABS_DISTANCE, value: -1 })
  ev.push_back(input_event{ type:EV_ABS, code:ABS_PRESSURE, value: -1})
  ev.push_back(input_event{ type:EV_ABS, code:ABS_Y, value: -1 })
  ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })

  return ev

vector<input_event> pen_down(int x, y, points=10):
  vector<input_event> ev
  ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })
  ev.push_back(input_event{ type:EV_KEY, code:BTN_TOOL_PEN, value: 1 })
  ev.push_back(input_event{ type:EV_KEY, code:BTN_TOUCH, value: 1 })
  ev.push_back(input_event{ type:EV_ABS, code:ABS_Y, value: get_pen_x(x) })
  ev.push_back(input_event{ type:EV_ABS, code:ABS_X, value: get_pen_y(y) })
  ev.push_back(input_event{ type:EV_ABS, code:ABS_DISTANCE, value: 0 })
  ev.push_back(input_event{ type:EV_ABS, code:ABS_PRESSURE, value: 4000 })
  ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })

  for int i = 0; i < points; i++:
    ev.push_back(input_event{ type:EV_ABS, code:ABS_PRESSURE, value: 4000 })
    ev.push_back(input_event{ type:EV_ABS, code:ABS_PRESSURE, value: 4001 })
    ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })

  return ev

vector<input_event> pen_move(int ox, oy, x, y, int points=10):
  ev := pen_down(ox, oy)
  double dx = float(x - ox) / float(points)
  double dy = float(y - oy) / float(points)

  ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })
  for int i = 0; i <= points; i++:
    ev.push_back(input_event{ type:EV_ABS, code:ABS_Y, value: get_pen_x(ox + (i*dx)) })
    ev.push_back(input_event{ type:EV_ABS, code:ABS_X, value: get_pen_y(oy + (i*dy)) })
    ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })

  return ev

vector<input_event> pen_up():
  vector<input_event> ev
  ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })
  ev.push_back(input_event{ type:EV_KEY, code:BTN_TOOL_PEN, value: 0 })
  ev.push_back(input_event{ type:EV_KEY, code:BTN_TOUCH, value: 0 })
  ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })

  return ev

def btn_press(int button):
  pass

def write_events(int fd, vector<input_event> events, int sleep_time=1000):
  vector<input_event> send
  for auto event : events:
    send.push_back(event)
    if event.type == EV_SYN:
      if sleep_time:
        usleep(sleep_time)
      input_event *out = (input_event*) malloc(sizeof(input_event) * send.size())
      for int i = 0; i < send.size(); i++:
        out[i] = send[i]

      write(fd, out, sizeof(input_event) * send.size())
      send.clear()
      free(out)

  if send.size() > 0:
    debug "DIDN'T SEND", send.size(), "EVENTS"

int finger_x, finger_y, pen_x, pen_y
void act_on_line(string);
void pen_draw_rectangle(int x1, y1, x2, y2):
  if x2 == -1:
    x2 = pen_x
    y2 = pen_y
  debug "DRAWING RECT", x1, y1, x2, y2
  act_on_line("pen down " + to_string(x1) + " " + to_string(y1))
  act_on_line("pen move " + to_string(x1) + " " + to_string(y2))
  act_on_line("pen move " + to_string(x2) + " " + to_string(y2))
  act_on_line("pen move " + to_string(x2) + " " + to_string(y1))
  act_on_line("pen move " + to_string(x1) + " " + to_string(y1))
  act_on_line("pen up ")

void pen_draw_line(int x1, y1, x2, y2):
  if x2 == -1:
    x2 = pen_x
    y2 = pen_y

  debug "DRAWING LINE", x1, y1, x2, y2
  act_on_line("pen down " + to_string(x1) + " " + to_string(y1))
  act_on_line("pen move " + to_string(x2) + " " + to_string(y2))
  act_on_line("pen up")

void pen_draw_circle(int ox, oy, r1, r2, points=360):

  act_on_line("pen down " + to_string(int(ox + r1)) + " " + to_string(int(oy)))
  denom := points/(2*3.14)
  old_move_pts := move_pts
  move_pts = 10
  for i := 0; i < points+10; i++:
    rx := cos(i / denom) * r1
    ry := sin(i / denom) * r1
    act_on_line("fastpen move " + to_string(int(ox + rx)) + " " + to_string(int(oy + ry)))
  move_pts = old_move_pts
  act_on_line("pen up")

void pen_draw_circle(int x1, y1, radius):
  if radius <= 1:
    debug "INVALID RADIUS FOR CIRCLE", radius
    return

  pass



int touch_fd, pen_fd
void act_on_line(string line):
  stringstream ss(line)
  string action, tool
  ss >> tool >> action;
  int x, y, ox=-1, oy=-1
  tokens := str_utils::split(line, ' ')

  if tool == "swipe":
    if action == "left":
      write_events(touch_fd, finger_up())
      write_events(touch_fd, finger_move(200, 500, 1000, 500, 20)) // swipe right
      write_events(touch_fd, finger_up())
      usleep(100 * 1000)
    else if action == "right":
      write_events(touch_fd, finger_up())
      write_events(touch_fd, finger_move(1000, 500, 200, 500, 20)) // swipe right
      write_events(touch_fd, finger_up())
      usleep(100 * 1000)
    else:
      debug "UNKNOWN SWIPE DIRECTION", action
    return

  if action == "move":
    if len(tokens) == 4:
      ss >> x >> y
    else if len(tokens) == 6:
      ss >> ox >> oy >> x >> y
    else:
      debug "UNRECOGNIZED MOVE LINE", line, "REQUIRES 2 or 4 COORDINATES"
  if action == "rectangle" || action == "line" || action == "circle":
    if len(tokens) == 6:
      ss >> ox >> oy >> x >> y
    else:
      debug "UNRECOGNIZED DRAW LINE", line, "REQUIRES 4 COORDINATES"

  if action == "down":
    if len(tokens) == 4:
      ss >> x >> y
    else:
      debug "UNRECOGNIZED DOWN LINE", line, "REQUIRES 2 COORDINATES"

  bsleep := 10
  if tool == "fastpen":
    bsleep = 2
  if tool == "pen" || tool == "fastpen":
    if action == "up":
      write_events(pen_fd, pen_up())
    else if action == "down":
      write_events(pen_fd, pen_down(x, y))
      pen_x = x
      pen_y = y
    else if action == "move":
      if ox != -1 && oy != -1:
        write_events(pen_fd, pen_move(ox, oy, x, y, move_pts), bsleep)
      else:
        write_events(pen_fd, pen_move(pen_x, pen_y, x, y, move_pts), bsleep)
      pen_x = x
      pen_y = y
    else if action == "line":
      pen_draw_line(ox, oy, x, y)
      usleep(200 * 1000)
    else if action == "rectangle":
      pen_draw_rectangle(ox, oy, x, y)
      usleep(200 * 1000)
    else if action == "circle":
      pen_draw_circle(ox, oy, x, y)
      usleep(200 * 1000)

    else:
      debug "UNKNOWN ACTION", action, "IN", line
  else if tool == "finger":
    if action == "up":
      write_events(touch_fd, finger_up())
    else if action == "down":
      write_events(touch_fd, finger_down(x, y))
      finger_x = x
      finger_y = y
    else if action == "move":
      if ox != -1 && oy != -1:
        write_events(touch_fd, finger_move(ox, oy, x, y))
      else:
        write_events(touch_fd, finger_move(finger_x, finger_y, x, y))
      finger_x = x
      finger_y = y
    else:
      debug "UNKNOWN ACTION", action, "IN", line
  else:
    debug "UNKNOWN TOOL", tool, "IN", line




def main(int argc, char **argv):
  fd0 := open("/dev/input/event0", O_RDWR)
  fd1 := open("/dev/input/event1", O_RDWR)
  fd2 := open("/dev/input/event2", O_RDWR)

  if input::id_by_capabilities(fd0) == input::EV_TYPE::TOUCH:
    touch_fd = fd0
  if input::id_by_capabilities(fd1) == input::EV_TYPE::TOUCH:
    touch_fd = fd1
  if input::id_by_capabilities(fd2) == input::EV_TYPE::TOUCH:
    touch_fd = fd2

  if input::id_by_capabilities(fd0) == input::EV_TYPE::STYLUS:
    pen_fd = fd0
  if input::id_by_capabilities(fd1) == input::EV_TYPE::STYLUS:
    pen_fd = fd1
  if input::id_by_capabilities(fd2) == input::EV_TYPE::STYLUS:
    pen_fd = fd2

  write_events(touch_fd, finger_up())
  write_events(pen_fd, pen_clear())

  string line
  while getline(cin, line):
    act_on_line(line)

  write_events(touch_fd, finger_up())
  write_events(pen_fd, pen_up())

