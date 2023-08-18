//+------------------------------------------------------------------+
//|                                           Bot_Click_To_Trade.mq5 |
//|                                      Copyright 2023, Vuong Pham. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Vuong Pham."
#property link      "https://www.mql5.com"
#property version   "1.00"

input int fMA_inp = 8;  // fast EMA
input int sMA_inp = 14; // slow EMA

input ENUM_TIMEFRAMES tframe_trade   = PERIOD_M1;   // khung thoi gian trade
input ENUM_TIMEFRAMES tframe_base_01 = PERIOD_M5;   // khung thoi gian co so 1
input ENUM_TIMEFRAMES tframe_base_02 = PERIOD_M30;  // khung thoi gian co so 2

input bool alert        = true; // cho phep alert
input bool all_signal   = true; // tat ca signal
input bool good_signal  = true; // signal dong pha 2 chart
input bool best_signal  = true; // signal dong pha 3 chart
input bool notification = true; // cho phep notification

input double sl_percent = 0.5;   // phan tram stoploss (%)
input int sl_point_gap  = 10;    // KC cong them vao dinh/day (point)

input bool is_break_even = true; // tu dong keo hoa von
input double ratio_rr    = 0.8;  // ty le (reward / risk) bat dau keo sl

//+------------------------------------------------------------------+
// CLASS TWO EMA CROSS
//+------------------------------------------------------------------+

enum status_chart
{
    _down_    = -1,
    _sideway_ = 0,
    _up_      = 1,
    
};

class Two_EMA
{
private:    
    int size, fhandle, shandle;
    double fMA[], sMA[];
    int f, s;
    double close_01, close_02;
    ENUM_TIMEFRAMES tframe;
    
    string name_label, text;
    int x, y, font_size;
    color clr;
    ENUM_BASE_CORNER corner;
    
public:
    // constructor
    Two_EMA(ENUM_TIMEFRAMES);
    
    // method
    status_chart is_up_down();
    status_chart is_cross_up_down();
    status_chart is_cross();

    void alert_up_down();
    void alert_cross();
    void draw_status();
    void post_telegram();
};

// constructor
Two_EMA :: Two_EMA(ENUM_TIMEFRAMES _tframe)
{
    size = 0; fhandle = 0; shandle = 0;
    f = 0; s = 0;
    close_01 = 0; close_02 = 0;
    tframe = _tframe;
    
    text = "";
    corner = CORNER_RIGHT_UPPER;
    if (tframe == tframe_trade)
    {
        name_label = "tframe_trade";        
        x = 220; y = 40;
        font_size = 12;        
    }
    else if (tframe == tframe_base_01)
    {
        name_label = "tframe_base_01";        
        x = 220; y = 70;
        font_size = 14;        
    }
    else if (tframe == tframe_base_02)
    {
        name_label = "tframe_base_02";        
        x = 220; y = 100;
        font_size = 14;        
    }
    
    // draw on chart
    draw_status();
}

// method
status_chart Two_EMA :: is_up_down()
{
    size = 1;
    fhandle = iMA(_Symbol, tframe, fMA_inp, 0, MODE_EMA, PRICE_CLOSE);
    shandle = iMA(_Symbol, tframe, sMA_inp, 0, MODE_EMA, PRICE_CLOSE);
    
    f = CopyBuffer(fhandle, 0, 1, size, fMA);
    s = CopyBuffer(shandle, 0, 1, size, sMA);
    
    close_01 = iClose(_Symbol, tframe, 1);
    
    if (close_01 > fMA[0] && close_01 > sMA[0])
    {
        return _up_;
    }
    
    if (close_01 < fMA[0] && close_01 < sMA[0])
    {
        return _down_;
    }
    
    return _sideway_;
}

status_chart Two_EMA :: is_cross_up_down()
{
    size = 2;
    fhandle = iMA(_Symbol, tframe, fMA_inp, 0, MODE_EMA, PRICE_CLOSE);
    shandle = iMA(_Symbol, tframe, sMA_inp, 0, MODE_EMA, PRICE_CLOSE);
    
    f = CopyBuffer(fhandle, 0, 1, size, fMA);
    s = CopyBuffer(shandle, 0, 1, size, sMA);
    
    close_01 = iClose(_Symbol, tframe, 1);
    close_02 = iClose(_Symbol, tframe, 2);
    
    if (close_02 < sMA[0] && close_01 > fMA[1] && close_01 > sMA[1])
    {
        return _up_;
    }
    
    if (close_02 > sMA[0] && close_01 < fMA[1] && close_01 < sMA[1])
    {
        return _down_;
    }
    
    return _sideway_;
}

status_chart Two_EMA :: is_cross()
{
    size = 2;
    fhandle = iMA(_Symbol, tframe, fMA_inp, 0, MODE_EMA, PRICE_CLOSE);
    shandle = iMA(_Symbol, tframe, sMA_inp, 0, MODE_EMA, PRICE_CLOSE);
    
    f = CopyBuffer(fhandle, 0, 1, size, fMA);
    s = CopyBuffer(shandle, 0, 1, size, sMA);
    
    if (fMA[0] < sMA[0] && fMA[1] > sMA[1])
    {
        return _up_;
    }
    
    else if (fMA[0] > sMA[0] && fMA[1] < sMA[1])
    {
        return _down_;
    }    
    
    return _sideway_;
}

void Two_EMA :: alert_up_down()
{
    if (is_cross_up_down() == _up_)
    {
        Alert(StringFormat("%s >>> %s: close Higher ... ", _Symbol, EnumToString(tframe)));
    }
    else if (is_cross_up_down() == _down_)
    {
        Alert(StringFormat("%s >>> %s: close Lower ... ", _Symbol, EnumToString(tframe)));
    }
}

void Two_EMA :: alert_cross()
{
    if (is_cross() == _up_)
    {
        Alert(StringFormat("%s >>> %s: Up cross ... ", _Symbol, EnumToString(tframe)));
    }
    else if (is_cross() == _down_)
    {
        Alert(StringFormat("%s >>> %s: Down cross ... ", _Symbol, EnumToString(tframe)));
    }
}

void Two_EMA :: draw_status()
{
    if (is_up_down() == _up_)
    {
        text = StringFormat("%s: _UP_", EnumToString(tframe));
        clr = clrBlue;
    }
    else if (is_up_down() == _down_)
    {
        text = StringFormat("%s: _DOWN_", EnumToString(tframe));
        clr = clrRed;
    }
    else if (is_up_down() == _sideway_)
    {
        text = StringFormat("%s: _SW_", EnumToString(tframe));
        clr = clrGray;
    }
    
    ObjectDelete(0, name_label);
    ObjectCreate(0, name_label, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name_label, OBJPROP_CORNER, corner);
    ObjectSetInteger(0, name_label, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name_label, OBJPROP_YDISTANCE, y);    
    ObjectSetString(0, name_label, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name_label, OBJPROP_FONTSIZE, font_size);
    ObjectSetInteger(0, name_label, OBJPROP_COLOR, clr);
}

//+------------------------------------------------------------------+
// CLASS CHECK NEW CANDLE
//+------------------------------------------------------------------+

class New_Candle
{
private:    
    ENUM_TIMEFRAMES tframe;
    datetime tcandle;
    
public:
    // constructor
    New_Candle(ENUM_TIMEFRAMES);
    
    // method 
    bool is_new_candle();
};

// constructor
New_Candle :: New_Candle(ENUM_TIMEFRAMES _tframe)
{
    tframe = _tframe;
    tcandle = iTime(_Symbol, _tframe, 0);
}

// method 
bool New_Candle :: is_new_candle()
{
    if (tcandle == iTime(_Symbol, tframe, 1))
    {
        tcandle = iTime(_Symbol, tframe, 0);
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
// CLASS BUTTON
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh> 
CTrade trade;
CPositionInfo position;

enum button_type
{
    _close_,
    _sell_,
    _buy_,
    _dollar_sl_,
    _points_,
    _vol_,
};

struct request
{
    double sl;
    double vol;
};

class Button
{
private:
    string name_button, text;
    int x, y, font_size;
    color clr;
    ENUM_BASE_CORNER corner;
    int width, height;
    button_type type;
    request req;
    double points, balance, dollar_sl;
    
public:
    // constructor
    Button(button_type); 
    
    // method
    void create_button();
    void get_stoploss_volume();
    void execution();
    void update_button_info();
};

// constructor
Button :: Button(button_type _type)
{
    corner = CORNER_RIGHT_UPPER;
    font_size = 16;
    width = 100; height = 50;
    type = _type;
    
    req.sl = 0;
    req.vol = 0.01;
    
    points = 0;
    balance = AccountInfoDouble(ACCOUNT_BALANCE);
    dollar_sl = balance * sl_percent / 100.0;
    
    if (_type == _close_)
    {
        name_button = "_close_";
        x = 220; y = 180;
        text = "CLOSE";
        clr = clrGray;
    }    
    else if (_type == _sell_)
    {
        name_button = "_sell_";
        x = 220; y = 250;
        text = "SELL";
        clr = clrRed;
    }
    else if (_type == _buy_)
    {
        name_button = "_buy_";
        x = 220; y = 320;
        text = "BUY";
        clr = clrBlue;
    }
    else if (_type == _dollar_sl_)
    {
        name_button = "_dollar_sl_";
        x = 110; y = 180;
        text = StringFormat("sl: $%0.1f", dollar_sl);
        clr = clrGray;
        font_size = 12;
    }
    else if (_type == _points_)
    {
        name_button = "_points_";
        x = 110; y = 250;
        text = StringFormat("points: %0.0f", points);
        clr = clrGray;
        font_size = 12;
    }
    else if (_type == _vol_)
    {
        name_button = "_vol_";
        x = 110; y = 320;
        text = StringFormat("vol: %0.2f", req.vol);
        clr = clrGray;
        font_size = 12;
    }
    
    // create button
    create_button();
}

// method
void Button :: create_button()
{
    ObjectDelete(0, name_button);
    ObjectCreate(0, name_button, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, name_button, OBJPROP_CORNER, corner);
    ObjectSetInteger(0, name_button, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name_button, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name_button, OBJPROP_XSIZE, width);
    ObjectSetInteger(0, name_button, OBJPROP_YSIZE, height);
    ObjectSetString(0, name_button, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name_button, OBJPROP_FONTSIZE, font_size);
    ObjectSetInteger(0, name_button, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name_button, OBJPROP_STATE, false);
    ObjectSetInteger(0, name_button, OBJPROP_ZORDER, 0);
}

void Button :: get_stoploss_volume()
{
    Two_EMA _tf_trade(tframe_trade);
    double current_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double current_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    if (_tf_trade.is_up_down() == _up_)
    {
        int idx = iLowest(_Symbol, tframe_trade, MODE_LOW, 26, 0);
        req.sl = iLow(_Symbol, tframe_trade, idx) - sl_point_gap * _Point;
        
        points = (current_ask - req.sl) / _Point;
        req.vol = dollar_sl / points;
        req.vol = NormalizeDouble(req.vol, 2);
    }
    else if (_tf_trade.is_up_down() == _down_)
    {
        int idx = iHighest(_Symbol, tframe_trade, MODE_HIGH, 26, 0);
        req.sl = iHigh(_Symbol, tframe_trade, idx) + sl_point_gap * _Point;
        
        points = (req.sl - current_bid) / _Point;
        req.vol = dollar_sl / points;
        req.vol = NormalizeDouble(req.vol, 2);
    }
}

void Button :: execution()
{
    double current_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double current_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    get_stoploss_volume();
    
    if (type == _buy_)
    {
        trade.Buy(req.vol, _Symbol, current_ask, req.sl);
    }
    else if (type == _sell_)
    {
        trade.Sell(req.vol, _Symbol, current_bid, req.sl);
    }
    else if (type == _close_)
    {
        int total = PositionsTotal();
        for(int i = 0; i < total; i++)
        {
            if (position.SelectByIndex(i))
            {
                if (position.Symbol() == _Symbol)
                {
                    trade.PositionClose(position.Ticket());
                }                
            }
        }
    }
    
    // release state button
    ObjectSetInteger(0, name_button, OBJPROP_STATE, false);
}

void Button :: update_button_info()
{
    get_stoploss_volume();
    
    if (type == _dollar_sl_)
    {
        text = StringFormat("sl: $%0.1f", dollar_sl);
        ObjectSetString(0, name_button, OBJPROP_TEXT, text);
    }
    else if (type == _points_)
    {
        text = StringFormat("points: %0.0f", points);
        ObjectSetString(0, name_button, OBJPROP_TEXT, text);
    }
    else if (type == _vol_)
    {
        text = StringFormat("vol: %0.2f", req.vol);
        ObjectSetString(0, name_button, OBJPROP_TEXT, text);
    }
    
    ObjectSetInteger(0, name_button, OBJPROP_STATE, false);
}

//+------------------------------------------------------------------+
// CREATE ALL INSTANCE
//+------------------------------------------------------------------+

Two_EMA tf_trade(tframe_trade);
Two_EMA tf_base01(tframe_base_01);
Two_EMA tf_base02(tframe_base_02);

New_Candle time_trade(tframe_trade);
New_Candle time_base01(tframe_base_01);
New_Candle time_base02(tframe_base_02);

Button btn_close(_close_);
Button btn_sell(_sell_);
Button btn_buy(_buy_);
Button btn_dollar_sl(_dollar_sl_);
Button btn_points(_points_);
Button btn_vol(_vol_);

//+------------------------------------------------------------------+
// ALERT GOOD SIGNAL
//+------------------------------------------------------------------+

string msg_up   = StringFormat("%s >>> %s: Up cross ... ", _Symbol, EnumToString(tframe_trade));
string msg_down = StringFormat("%s >>> %s: Down cross ... ", _Symbol, EnumToString(tframe_trade));

void alert_good_signal()
{
    if (tf_trade.is_cross() == _up_ && tf_base01.is_up_down() == _up_)
    {
        Alert(msg_up);
    }
    else if (tf_trade.is_cross() == _down_ && tf_base01.is_up_down() == _down_)
    {
        Alert(msg_down);
    }
}

//+------------------------------------------------------------------+
// ALERT BEST SIGNAL
//+------------------------------------------------------------------+

void alert_best_signal()
{
    if (tf_trade.is_cross() == _up_ && tf_base01.is_up_down() == _up_ && tf_base02.is_up_down() == _up_)
    {
        Alert(msg_up);
    }
    else if (tf_trade.is_cross() == _down_ && tf_base01.is_up_down() == _down_ && tf_base02.is_up_down() == _down_)
    {
        Alert(msg_down);
    }
}

//+------------------------------------------------------------------+
// NOTIFICATION
//+------------------------------------------------------------------+

void post_notification()
{
    if (tf_trade.is_cross() == _up_ && tf_base01.is_up_down() == _up_)
    {
        SendNotification(msg_up);
    }
    else if (tf_trade.is_cross() == _down_ && tf_base01.is_up_down() == _down_)
    {
        SendNotification(msg_down);
    }
}
    
//+------------------------------------------------------------------+
// TAKE BREAK_EVEN (SL = OPEN)
//+------------------------------------------------------------------+

int _total;
double order_open, order_sl, price_current, new_sl;
ulong order_ticket;
long _order_type;

void take_break_even()
{
    _total = PositionsTotal();
    for (int i = 0; i < _total; i++)
    {    
        if (PositionGetSymbol(i) == _Symbol)
        {
            price_current = PositionGetDouble(POSITION_PRICE_CURRENT);
            order_open = PositionGetDouble(POSITION_PRICE_OPEN);
            order_sl = PositionGetDouble(POSITION_SL);
            _order_type = PositionGetInteger(POSITION_TYPE);
            
            if ((_order_type == POSITION_TYPE_BUY && order_open > order_sl) ||
                (_order_type == POSITION_TYPE_SELL && order_open < order_sl))
            {
                if (MathAbs(price_current - order_open) / MathAbs(order_sl - order_open) >= ratio_rr)
                {
                    order_ticket = PositionGetInteger(POSITION_TICKET);
                    
                    if (_order_type == POSITION_TYPE_BUY)
                    {
                        new_sl = order_open + sl_point_gap * _Point / 3;
                    }
                    else if (_order_type == POSITION_TYPE_SELL)
                    {
                        new_sl = order_open - sl_point_gap * _Point / 3;
                    }
                    
                    bool m = trade.PositionModify(order_ticket, new_sl, 0);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
// RUNNING EVERY TICK
//+------------------------------------------------------------------+

void OnTick()
{
    if (time_base01.is_new_candle())
    {
        if (alert)
        {
            if (all_signal)
            {
                tf_base01.alert_up_down();
                tf_base01.alert_cross();
            }
            else if (good_signal)
            {
                tf_base01.alert_cross();
            }
        }        
        tf_base01.draw_status();
    }
    
    if (time_base02.is_new_candle())
    {
        if (alert)
        {
            if (all_signal)
            {
                tf_base02.alert_up_down();
                tf_base02.alert_cross();
            }
            else if (good_signal)
            {
                tf_base02.alert_cross();
            }
        }        
        tf_base02.draw_status();
    }
    
    if (time_trade.is_new_candle())
    {
        if (alert)
        {
            if (all_signal)
            {
                tf_trade.alert_cross();
            }
            else if (good_signal)
            {
                alert_good_signal();
            }
            else if (best_signal)
            {
                alert_best_signal();
            }
        }
        
        if (notification)
        {
            if (good_signal || best_signal)
            {
                post_notification();
            }
        }
        
        tf_trade.draw_status();
        
        btn_dollar_sl.update_button_info();
        btn_points.update_button_info();
        btn_vol.update_button_info();
    }
    
    if (is_break_even)
    {
        take_break_even();
    }
}

//+------------------------------------------------------------------+
// CHECK BUY/SELL EVENT FROM BUTTON
//+------------------------------------------------------------------+

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    if (id == CHARTEVENT_OBJECT_CLICK)
    {
        if (sparam == "_buy_")
        {
            btn_buy.execution();
        }
        else if (sparam == "_sell_")
        {
            btn_sell.execution();
        }
        else if (sparam == "_close_")
        {
            btn_close.execution();
        }
    }
}

//+------------------------------------------------------------------+
// DESTROYS ALL
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{
    ObjectsDeleteAll(0);
}

//+------------------------------------------------------------------+
// SETUP & EXPIRED
//+------------------------------------------------------------------+

int OnInit()
{
    if (TimeCurrent() > D'01.07.2024')
        return (INIT_FAILED); 
    
    tf_trade.draw_status();
    tf_base01.draw_status();
    tf_base02.draw_status();
        
    btn_close.create_button();
    btn_buy.create_button();
    btn_sell.create_button();
    
    btn_dollar_sl.create_button();
    btn_points.create_button();
    btn_vol.create_button();
    
    return (INIT_SUCCEEDED);
}

