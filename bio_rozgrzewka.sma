#include <amxmodx>             // AMX Mod X 
#include <amxmisc> 

new czas = 60 
new resety=3 
new noze=0 
new restart_title[1][] = { "La Resistance" } 

new misc[3][]={"misc/one.wav","misc/two.wav","misc/three.wav"} 

new bylo_juz=0 

public plugin_init() 
{ 
    register_plugin("ROund STart REstart","1.9","Miczu & Ox!d3") // Mi te¿ siê coœ nale¿y ;D 
    
    register_event("HLTV","Event_StartRound","a","1=0","2=0") 

    return PLUGIN_CONTINUE 
} 

public test_it(){ 
    new players[32], num, num2 
    get_players(players,num,"e","TERRORIST") 
    get_players(players,num2,"e","CT") 
    if(num2<1 || num<1) return 0 
    return 1 
} 

public client_disconnect(id){ 
    set_task(0.3,"disconnect",0) 
} 

public disconnect(){ 
    if(test_it()==0 && noze==0) bylo_juz=0 
} 

public Event_StartRound(){ 
    if(test_it()==0 && noze==0) bylo_juz=0 
    set_task(0.2,"restart_odlicz", 0) 
    set_task(6.0,"restart_odlicz", 0) 
} 

public client_PreThink ( id ) 
{ 
    if(noze) client_cmd(id,"weapon_knife") 
} 

public restart_odlicz(){ 
        
    if(test_it() && noze==0 && bylo_juz==0){ 
        noze=1 
        bylo_juz=1 
        czas=60 
        resety=3 
        pause("ac","Antirusher.amxx") 
        pause("ac","M_Antirusher.amxx") 
        pause("ac","M_Antirusher_2.4.amxx") 
        pause("ac","M_Antirusher_2.5.amxx") 
        pause("ac","M_Antirusher_2.5b.amxx") 
        pause("ac","imessage.amxx") 
        pause("ac","scrollmsg.amxx") 
        set_task(3.0,"muza_on", 0) 
        set_task(1.0,"wyswietl_res",8188,"",0,"b") 
    } 
} 

public muza_on(){ 
    client_cmd(0,"stopsound") 
    client_cmd(0,"spk misc/play_ejo.wav") 
} 

public wyswietl_res(){ 

    new jac1=random_num(0,255) 
    new jac2=random_num(0,255) 
    new jac3=random_num(0,255)    

    set_hudmessage(jac1, jac2, jac3, 0.65, 0.75, 2, 0.02, 1.0, 0.01, 0.1, 10) 
    show_hudmessage(0,"==================^n    *%s *^n  RESTART ZA: %i sec^n==================", restart_title, czas) 
    czas-- 
    if(czas==3){ 
        set_task(0.7,"restart_rundy_0", 0) 
    } 
} 

public restart_rundy_play(){ 
    set_hudmessage(10, 255, 40, -1.0, 0.30, 0, 6.0, 6.0, 0.5, 0.15, 4) 
    show_hudmessage(0,"===================^n* LIVE LA RESISTANCE *^n===================") 
} 

public restart_rundy(){ 
    unpause("ac","Antirusher.amxx") 
    unpause("ac","M_Antirusher.amxx") 
    unpause("ac","M_Antirusher_2.4.amxx") 
    unpause("ac","M_Antirusher_2.5.amxx") 
    unpause("ac","M_Antirusher_2.5b.amxx") 
    unpause("ac","imessage.amxx") 
    unpause("ac","scrollmsg.amxx") 
    client_cmd(0,"stopsound") 
    client_cmd(0,"spk misc/reset.wav")  
    server_cmd("sv_restart 1") 
    remove_task(8188) 
    set_task(2.0,"restart_rundy_play", 0) 
} 

public restart_rundy_0(){ 
    client_cmd(0,"stopsound") 
    client_cmd(0,"spk %s",misc[resety-1]) 
    resety-- 
    if(resety==0){ 
        noze=0 
        set_task(1.0,"restart_rundy", 0) 
    } 
    else set_task(1.2,"restart_rundy_0", 0) 
} 

public plugin_precache() 
{ 
    precache_sound("misc/play_ejo.wav") 
    precache_sound("misc/reset.wav") 
    precache_sound(misc[0]) 
    precache_sound(misc[1]) 
    precache_sound(misc[2]) 

    return PLUGIN_CONTINUE 
}