//+------------------------------------------------------------------+
//|                                           Bot_Click_To_Trade.mq5 |
//|                                      Copyright 2023, Vuong Pham. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Vuong Pham."
#property link      "https://www.mql5.com"
#property version   "1.00"

input int fMA_inp = 8;  // fast EMA
input int sMA_inp = 13; // slow EMA

input ENUM_TIMEFRAMES tframe_trade   = PERIOD_M3;   // khung thoi gian trade
input ENUM_TIMEFRAMES tframe_base_01 = PERIOD_M15;  // khung thoi gian co so 1
input ENUM_TIMEFRAMES tframe_base_02 = PERIOD_H1;   // khung thoi gian co so 2
input ENUM_TIMEFRAMES tframe_base_03 = PERIOD_H4;   // khung thoi gian co so 3

input bool alert        = false;  // cho phep alert
input bool all_signal   = false;  // tat ca signal
input bool good_signal  = true;   // signal dong pha 2 chart
input bool best_signal  = true;   // signal dong pha 3 chart
input bool notification = false;  // cho phep notification

input double sl_percent = 1.0;   // phan tram stoploss (%)
input int sl_point_gap  = 50;    // KC cong them vao dinh/day (point)

input bool is_break_even = true;        // tu dong keo hoa von
input double ratio_rr    = 0.7;         // ty le (reward / risk) bat dau keo sl
input bool clear_all_objects = false;   // xoa moi object

input bool draw_rec     = true;         // ve phien giao dich
input bool f_draw_vline = true;         // ve duong vline bat dau
input bool s_draw_vline = true;         // ve duong vline ket thuc
input int offset_ss     = 0;            // offset gio gd theo mua
input bool is_chart_setting = true;     // template mac dinh

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
    void delete_objects();
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
        x = 200; y = 80;
        font_size = 10;        
    }
    else if (tframe == tframe_base_01)
    {
        name_label = "tframe_base_01";        
        x = 200; y = 105;
        font_size = 11;        
    }
    else if (tframe == tframe_base_02)
    {
        name_label = "tframe_base_02";        
        x = 200; y = 130;
        font_size = 13;        
    }
    else if (tframe == tframe_base_03)
    {
        name_label = "tframe_base_03";        
        x = 200; y = 160;
        font_size = 13;        
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
        clr = clrSeaGreen;
    }
    else if (is_up_down() == _down_)
    {
        text = StringFormat("%s: _DOWN_", EnumToString(tframe));
        clr = clrCrimson;
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

void Two_EMA :: delete_objects()
{
    ObjectDelete(0, name_label);
}
//+------------------------------------------------------------------+
// CLASS CHECK NEW CANDLE
//+------------------------------------------------------------------+

class Time_Candle
{
private:    
    ENUM_TIMEFRAMES tframe;
    datetime tcandle;
    
public:
    // constructor
    Time_Candle(ENUM_TIMEFRAMES);
    
    // method 
    bool is_new_candle();
};

// constructor
Time_Candle :: Time_Candle(ENUM_TIMEFRAMES _tframe)
{
    tframe = _tframe;
    tcandle = iTime(_Symbol, _tframe, 0);
}

// method 
bool Time_Candle :: is_new_candle()
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
    _p_sl_sell_,
    _p_sl_buy_,
};

struct request
{
    double sl_b, sl_s;
    double vol_b, vol_s;
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
    double points_b, points_s, balance, sl_dollar;
    
public:
    // constructor
    Button(button_type); 
    
    // method
    void create_button();
    void get_stoploss_volume();
    double cal_volume(double);
    void execution();
    void update_button_info();
    void delete_objects();
};

// constructor
Button :: Button(button_type _type)
{
    corner = CORNER_RIGHT_UPPER;
    font_size = 16;
    width = 90; height = 40;
    type = _type;
    
    req.sl_b = 0;
    req.vol_b = 0.01;
    req.sl_s = 0;
    req.vol_s = 0.01;
    
    points_b = 0; points_s = 0;
    balance = AccountInfoDouble(ACCOUNT_BALANCE);
    sl_dollar = balance * sl_percent / 100.0;
    
    if (_type == _close_)
    {
        name_button = "_close_";
        x = 200; y = 210;
        text = "CLOSE";
        clr = clrGray;
    }    
    else if (_type == _sell_)
    {
        name_button = "_sell_";
        x = 200; y = 270;
        text = "SELL";
        clr = clrRed;
    }
    else if (_type == _buy_)
    {
        name_button = "_buy_";
        x = 200; y = 330;
        text = "BUY";
        clr = clrBlue;
    }
    else if (_type == _dollar_sl_)
    {
        name_button = "_dollar_sl_";
        x = 100; y = 210;
        text = StringFormat("sl ~ %0.1f $", sl_dollar);
        clr = clrGray;
        font_size = 10;
    }
    else if (_type == _p_sl_sell_)
    {
        name_button = "_p_sl_sell_";
        x = 100; y = 270;
        text = StringFormat("%d ~ %0.2f", int(points_s), req.vol_s);
        clr = clrGray;
        font_size = 10;
    }
    else if (_type == _p_sl_buy_)
    {
        name_button = "_p_sl_buy_";
        x = 100; y = 330;
        text = StringFormat("%d ~ %0.2f", int(points_b), req.vol_b);
        clr = clrGray;
        font_size = 10;
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
    
    balance = AccountInfoDouble(ACCOUNT_BALANCE);
    sl_dollar = balance * sl_percent / 100.0;
    
    // sl & vol: BUY
    int idx_low = iLowest(_Symbol, tframe_trade, MODE_LOW, 26, 0);
    req.sl_b = iLow(_Symbol, tframe_trade, idx_low) - sl_point_gap * _Point;
    points_b = (current_ask - req.sl_b) / _Point;
    
    if (_Digits == 3 && (_Symbol == "XAUUSD" || _Symbol == "XAUUSDm"))
    {
        req.sl_b = iLow(_Symbol, tframe_trade, idx_low) - sl_point_gap * (10 * _Point);
        points_b = (current_ask - req.sl_b) / (_Point * 10);
    }
    
    req.vol_b = cal_volume(req.sl_b);
    
    // sl & vol: SELL
    int idx_high = iHighest(_Symbol, tframe_trade, MODE_HIGH, 26, 0);
    req.sl_s = iHigh(_Symbol, tframe_trade, idx_high) + sl_point_gap * _Point;
    points_s = (req.sl_s - current_bid) / _Point;
    
    if (_Digits == 3 && (_Symbol == "XAUUSD" || _Symbol == "XAUUSDm"))
    {
        req.sl_s = iHigh(_Symbol, tframe_trade, idx_high) + sl_point_gap * (10 * _Point);
        points_s = (req.sl_s - current_bid) / (_Point * 10);
    }
    
    req.vol_s = cal_volume(req.sl_s);
}

double Button :: cal_volume(double sl_price)
{
    string f_pair = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_BASE);
    string s_pair = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);
    
    double curr_price = iClose(_Symbol, PERIOD_CURRENT, 0);
    double contract_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    
    double pip_1_lot = 0;
    
    if (s_pair == "USD")
    {
        pip_1_lot = contract_size * MathAbs(sl_price - curr_price);
    }
    else if (f_pair == "USD")
    {
        pip_1_lot = contract_size * MathAbs(sl_price - curr_price) / sl_price;
    }
    else
    {
        double ex_ratio = 0;
        ex_ratio = iClose(f_pair + "USD", PERIOD_CURRENT, 0);
        
        if (ex_ratio != 0)
        {
            pip_1_lot = contract_size * MathAbs(sl_price - curr_price) * ex_ratio;
        }
        else 
        {
            ex_ratio = iClose("USD" + s_pair, PERIOD_CURRENT, 0);
            if (ex_ratio != 0)
            {
                pip_1_lot = contract_size * MathAbs(sl_price - curr_price) / ex_ratio;
            }
        }
    }
    
    // volume
    double vol = 0.01;
    if (pip_1_lot != 0)
    {
        vol = sl_dollar / pip_1_lot;
    }
    
    return NormalizeDouble(vol, 2);
}

void Button :: execution()
{
    double current_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double current_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    get_stoploss_volume();
    
    if (type == _buy_)
    {
        trade.Buy(req.vol_b, _Symbol, current_ask, req.sl_b);
    }
    else if (type == _sell_)
    {
        trade.Sell(req.vol_s, _Symbol, current_bid, req.sl_s);
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
        text = StringFormat("sl ~ %0.1f $", sl_dollar);
        ObjectSetString(0, name_button, OBJPROP_TEXT, text);
    }
    else if (type == _p_sl_sell_)
    {
        text = StringFormat("%d ~ %0.2f", int(points_s), req.vol_s);
        ObjectSetString(0, name_button, OBJPROP_TEXT, text);
    }
    else if (type == _p_sl_buy_)
    {
        text = StringFormat("%d ~ %0.2f", int(points_b), req.vol_b);
        ObjectSetString(0, name_button, OBJPROP_TEXT, text);
    }
    
    ObjectSetInteger(0, name_button, OBJPROP_STATE, false);
}

void Button :: delete_objects()
{
    ObjectDelete(0, name_button);
}

//+------------------------------------------------------------------+
// SESSION CLASS
//+------------------------------------------------------------------+

enum session
{
    _sydney_,
    _tokyo_,
    _london_,
    _newyork_
};

class Trading_Session
{
private:
    MqlDateTime dt;
    int session_name;
    string name1, name2, name_rec;
    datetime date, time1, time2;
    double price1, price2, max, min, pass_price;
    color clr;
    ENUM_LINE_STYLE style1, style2, style_rec;
    int width1, width2;
    bool selection, ray, back, fill;
    bool f_draw_vline_, s_draw_vline_, draw_rec_;
    
public:
    void Trading_Session(int);
    void get_coordinates();
    void draw_object();
    void delete_objects();
};

// contructor
Trading_Session :: Trading_Session(int _name)
{
    session_name = _name;
    style1 = STYLE_DOT;
    style2 = STYLE_DOT;
    style_rec = STYLE_SOLID;
    
    width1 = 1;
    width2 = 1;
    
    selection = true;
    ray = true;
    back = true;
    fill = true;
    
    get_coordinates();
    
    if (session_name == _sydney_)
    {
        name1 = "_sydney_1";
        name2 = "_sydney_2";
        name_rec = "_sydney_rec";
        clr = clrDarkTurquoise;
    }
    if (session_name == _tokyo_)
    {
        name1 = "_tokyo_1";
        name2 = "_tokyo_2";
        name_rec = "_tokyo_rec";
        clr = clrYellowGreen;
    }
    if (session_name == _london_)
    {
        name1 = "_london_1";
        name2 = "_london_2";
        name_rec = "_london_rec";
        clr = clrRed;
    }
    if (session_name == _newyork_)
    {
        name1 = "_newyork_1";
        name2 = "_newyork_2";
        name_rec = "_newyork_rec";
        clr = clrYellow;
    }
}

// method
void Trading_Session :: get_coordinates()
{
    TimeTradeServer(dt);
    date = StringToTime(StringFormat("D'%d.%d.%d'", dt.year, dt.mon, dt.day));
    
    max = ChartGetDouble(0, CHART_FIXED_MAX);
    min = ChartGetDouble(0, CHART_FIXED_MIN);
    
    pass_price = iClose(_Symbol, PERIOD_M5, 1);
    
    if (session_name == _sydney_)
    {        
        time1 = date + (0 + offset_ss)*3600;
        price1 = max - (max - min)*0.005;
        
        time2 = date + (9 + offset_ss)*3600;
        price2 = max - (max - min)*0.015;
        
        if (pass_price >= min + 2 / 3.0 * (max - min))
        {
            price1 = min + (max - min)*0.005;
            price2 = min + (max - min)*0.015;
        }
    }
    
    if (session_name == _tokyo_)
    {
        time1 = date + (3 + offset_ss)*3600;
        price1 = max - (max - min)*0.02;
        
        time2 = date + (12 + offset_ss)*3600;
        price2 = max - (max - min)*0.03;
        
        if (pass_price >= min + 2 / 3.0 * (max - min))
        {
            price1 = min + (max - min)*0.020;
            price2 = min + (max - min)*0.030;
        }
    }
    
    if (session_name == _london_)
    {
        time1 = date + (10 + offset_ss)*3600;
        price1 = max - (max - min)*0.035;
        
        time2 = date + (19 + offset_ss)*3600;
        price2 = max - (max - min)*0.045;
        
        if (pass_price >= min + 2 / 3.0 * (max - min))
        {
            price1 = min + (max - min)*0.035;
            price2 = min + (max - min)*0.045;
        }
    }
    
    if (session_name == _newyork_)
    {
        time1 = date + (15 + offset_ss)*3600;
        price1 = max - (max - min)*0.05;
        
        time2 = date + (24 + offset_ss)*3600;
        price2 = max - (max - min)*0.06;
        
        if (pass_price >= min + 2 / 3.0 * (max - min))
        {
            price1 = min + (max - min)*0.050;
            price2 = min + (max - min)*0.060;
        }
    }
}

void Trading_Session :: draw_object()
{    
    f_draw_vline_ = f_draw_vline;
    s_draw_vline_ = s_draw_vline;
    draw_rec_ = draw_rec;
    
    if (_Period >= PERIOD_H1)
    {
        f_draw_vline_ = false;
        s_draw_vline_ = false;
        draw_rec_ = false;
    }
    
    get_coordinates();
    
    // vline 1
    if (f_draw_vline_)
    {
        ObjectDelete(0, name1);
        
        if (TimeTradeServer() == TimeGMT())
        {
            ObjectCreate(0, name1, OBJ_VLINE, 0, time1 - 3*3600, 0);
        } 
        else
        {
            ObjectCreate(0, name1, OBJ_VLINE, 0, time1, 0);
        }
        
        ObjectSetInteger(0, name1, OBJPROP_COLOR, clr);
        ObjectSetInteger(0, name1, OBJPROP_STYLE, style1);
        ObjectSetInteger(0, name1, OBJPROP_WIDTH, width1);
        ObjectSetInteger(0, name1, OBJPROP_BACK, back);
        ObjectSetInteger(0, name1, OBJPROP_SELECTABLE, selection);
        ObjectSetInteger(0, name1, OBJPROP_RAY, ray);
    }
    
    // vline 2
    if (s_draw_vline_)
    {    
        ObjectDelete(0, name2);
        
        if (TimeTradeServer() == TimeGMT())
        {
            ObjectCreate(0, name2, OBJ_VLINE, 0, time2 - 3*3600, 0);
        } 
        else
        {
            ObjectCreate(0, name2, OBJ_VLINE, 0, time2, 0);
        }
        
        ObjectSetInteger(0, name2, OBJPROP_COLOR, clr);
        ObjectSetInteger(0, name2, OBJPROP_STYLE, style2);
        ObjectSetInteger(0, name2, OBJPROP_WIDTH, width2);
        ObjectSetInteger(0, name2, OBJPROP_BACK, back);
        ObjectSetInteger(0, name2, OBJPROP_SELECTABLE, selection);
        ObjectSetInteger(0, name2, OBJPROP_RAY, ray);
    }
    
    // rectangle
    if (draw_rec_)
    {    
        ObjectDelete(0, name_rec);
        
        if (TimeTradeServer() == TimeGMT())
        {
            ObjectCreate(0, name_rec, OBJ_RECTANGLE, 0, time1 - 3*3600, price1, time2 - 3*3600, price2);
        } 
        else
        {
            ObjectCreate(0, name_rec, OBJ_RECTANGLE, 0, time1, price1, time2, price2);
        }
        
        ObjectSetInteger(0, name_rec, OBJPROP_COLOR, clr);
        ObjectSetInteger(0, name_rec, OBJPROP_STYLE, style_rec);
        ObjectSetInteger(0, name_rec, OBJPROP_WIDTH, width1);
        ObjectSetInteger(0, name_rec, OBJPROP_BACK, back);
        ObjectSetInteger(0, name_rec, OBJPROP_SELECTABLE, selection);
        ObjectSetInteger(0, name_rec, OBJPROP_FILL, fill);
    }
    if ((!f_draw_vline_ || !s_draw_vline_) && !draw_rec_) 
    {
        delete_objects();
    }
}

void Trading_Session :: delete_objects()
{
    ObjectDelete(0, name1);
    ObjectDelete(0, name2);
    ObjectDelete(0, name_rec);
}

//+------------------------------------------------------------------+
// COUNTING TIME
//+------------------------------------------------------------------+

class Count_Time
{
private:
    string tt_name;
    datetime time, time1, subtime; 
    int riptime, hh, mm, ss;
    double price;
    string text;
    int font_size;
    color clr;
    bool back;
    
public:
    Count_Time();
    void text_time();
    void delete_objects();
};

Count_Time :: Count_Time()
{
    tt_name = "text_time";
    time = TimeCurrent() + _Period * 2 * 60;
    price = iClose(_Symbol, _Period, 0);
    text = "";
    font_size = 8;
    clr = clrOrange;
    back = true;
}

void Count_Time :: text_time()
{
    time = TimeCurrent() + _Period * 2 * 60;
    price = iClose(_Symbol, _Period, 0);
    
    subtime = TimeCurrent() - iTime(_Symbol, _Period, 0);
    riptime = _Period * 60 - int(subtime);
    
    if (_Period >= PERIOD_H1)
    {
        text = "";
        ObjectDelete(0, tt_name);
    }
    else
    {
        mm = riptime / 60;
        ss = riptime % 60;
        
        if (mm < 10)
        {
            if (ss < 10)
            {
                text = StringFormat("<<< 0%d:0%d", mm, ss);
            }
            else
            {
                text = StringFormat("<<< 0%d:%d", mm, ss);
            }
        }
        else
        {
            if (ss < 10)
            {
                text = StringFormat("<<< %d:0%d", mm, ss);
            }
            else
            {
                text = StringFormat("<<< %d:%d", mm, ss);
            }
        }
    }
    
    ObjectDelete(0, tt_name);
    ObjectCreate(0, tt_name, OBJ_TEXT, 0, time, price);
    ObjectSetString(0, tt_name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, tt_name, OBJPROP_FONTSIZE, font_size);
    ObjectSetInteger(0, tt_name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, tt_name, OBJPROP_BACK, back);
}

void Count_Time :: delete_objects()
{
    ObjectDelete(0, tt_name);
}

//+------------------------------------------------------------------+
// CREATE ALL INSTANCE
//+------------------------------------------------------------------+

Two_EMA tf_trade(tframe_trade);
Two_EMA tf_base01(tframe_base_01);
Two_EMA tf_base02(tframe_base_02);
Two_EMA tf_base03(tframe_base_03);

Time_Candle time_trade(tframe_trade);
Time_Candle time_base01(tframe_base_01);
Time_Candle time_base02(tframe_base_02);
Time_Candle time_base03(tframe_base_03);

Button btn_close(_close_);
Button btn_sell(_sell_);
Button btn_buy(_buy_);
Button btn_dollar_sl(_dollar_sl_);
Button btn_points(_p_sl_sell_);
Button btn_vol(_p_sl_buy_);

Trading_Session sydney(_sydney_);
Trading_Session tokyo(_tokyo_);
Trading_Session london(_london_);
Trading_Session newyork(_newyork_);

Count_Time count_time;

//+------------------------------------------------------------------+
// ALERT GOOD SIGNAL
//+------------------------------------------------------------------+

string msg_up   = StringFormat("%s >>> %s: Up cross ... ", _Symbol, EnumToString(tframe_trade));
string msg_down = StringFormat("%s >>> %s: Down cross ... ", _Symbol, EnumToString(tframe_trade));

void alert_good_signal()
{
    if (tf_trade.is_cross() == _up_ && (tf_base01.is_up_down() == _up_ || tf_base01.is_up_down() == _sideway_))
    {
        Alert(msg_up);
    }
    else if (tf_trade.is_cross() == _down_ && (tf_base01.is_up_down() == _down_ || tf_base01.is_up_down() == _sideway_))
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

int total_;
double order_open, order_sl, price_current, new_sl;
ulong order_ticket;
long _order_type;

void take_break_even()
{
    total_ = PositionsTotal();
    for (int i = 0; i < total_; i++)
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
// SHOW ORDERS AND VOLUME
//+------------------------------------------------------------------+

int countB, countS;
double volB, volS, profits;

void show_orders_volume()
{
    total_ = PositionsTotal();    
    profits = 0;
    
    countB = 0; 
    volB = 0;    
    
    countS = 0;
    volS = 0;
    
    for (int i = 0; i < total_; i++)
    {
        if (PositionGetSymbol(i) == _Symbol)
        {
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            {
                countB++;
                volB += position.Volume();
            }
            else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            {
                countS++;
                volS += position.Volume();
            }
            profits += position.Profit();
        }
    }
    string msg = "\n\n- - - - - - - - - - - - - - - - - -";
    msg += StringFormat("\n_____ %s _____", _Symbol);
    msg += StringFormat("\n\nBuy: %d - Volume: %0.2f\nSell.: %d - Volume: %0.2f", countB, volB, countS, volS);
    msg += StringFormat("\n\nPnL: $ %0.2f", profits);
    msg += "\n- - - - - - - - - - - - - - - - - -";
    Comment(msg);
}

//+------------------------------------------------------------------+
// RUNNING EVERY TICK
//+------------------------------------------------------------------+

void OnTick()
{   
    if (time_base03.is_new_candle())
    {
        if (alert)
        {
            tf_base03.alert_up_down();
            tf_base03.alert_cross();
        }        
        tf_base03.draw_status();
    }
    
    if (time_base02.is_new_candle())
    {
        if (alert)
        {
            tf_base02.alert_up_down();
            tf_base02.alert_cross();
        }        
        tf_base02.draw_status();
    }
    
    if (time_base01.is_new_candle())
    {
        if (alert)
        {
            if (all_signal || good_signal)
            {
                tf_base01.alert_up_down();
                tf_base01.alert_cross();
            }
            else if (best_signal)
            {
                tf_base01.alert_cross();
            }            
        }        
        tf_base01.draw_status();
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
        
        // update button
        btn_dollar_sl.update_button_info();
        btn_points.update_button_info();
        btn_vol.update_button_info();
        
        // session
        sydney.draw_object();
        tokyo.draw_object();
        london.draw_object();
        newyork.draw_object();
    }
    
    if (is_break_even)
    {
        take_break_even();
    }
    
    // comment volume
    show_orders_volume();
    
    // couting time
    count_time.text_time();
    
    Sleep(10);
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
// SETUP & EXPIRED
//+------------------------------------------------------------------+

int OnInit()
{
    if (TimeCurrent() > D'01.07.2024')
        return (INIT_FAILED); 
    
    // chart setting
    if (is_chart_setting)
    {
        ChartSetInteger(0, CHART_MODE, CHART_CANDLES);
        ChartSetInteger(0, CHART_SHIFT, true);
        ChartSetInteger(0, CHART_AUTOSCROLL, true);
        ChartSetInteger(0, CHART_SCALE, 2);
        ChartSetInteger(0, CHART_SHOW_ASK_LINE, true);
        ChartSetInteger(0, CHART_SHOW_GRID, false);
        ChartSetInteger(0, CHART_SHOW_TRADE_HISTORY, false);
        ChartSetInteger(0, CHART_SHOW_VOLUMES, true);
        ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrBlack);
        ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrWhite);
        ChartSetInteger(0, CHART_COLOR_CHART_UP, clrLime);
        ChartSetInteger(0, CHART_COLOR_CHART_DOWN, clrLime);
        ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, clrBlack);
        ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, clrWhite);
        ChartSetInteger(0, CHART_COLOR_BID, clrLightSlateGray);
        ChartSetInteger(0, CHART_COLOR_ASK, clrLightSlateGray);
        ChartSetInteger(0, CHART_COLOR_VOLUME, clrLimeGreen);
        ChartRedraw();
    }
    
    // status
    tf_trade.draw_status();
    tf_base01.draw_status();
    tf_base02.draw_status();
    tf_base03.draw_status();
        
    // button
    btn_close.create_button();
    btn_buy.create_button();
    btn_sell.create_button();
    
    btn_dollar_sl.create_button();
    btn_points.create_button();
    btn_vol.create_button();
    
    // session
    sydney.draw_object();
    tokyo.draw_object();
    london.draw_object();
    newyork.draw_object();
    
    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
// DESTROYS ALL
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{
    if (clear_all_objects)
    {
        ObjectsDeleteAll(0);    
    }
    
    tf_trade.delete_objects();
    tf_base01.delete_objects();
    tf_base02.delete_objects();
    tf_base03.delete_objects();
    
    btn_close.delete_objects();
    btn_buy.delete_objects();    
    btn_sell.delete_objects();
    btn_dollar_sl.delete_objects();
    btn_points.delete_objects();
    btn_vol.delete_objects();
    
    sydney.delete_objects();
    tokyo.delete_objects();
    london.delete_objects();
    newyork.delete_objects();
    
    count_time.delete_objects();
}

