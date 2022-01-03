#include < amxmodx >

enum _:CvarBits (<<=1) {
    BLOCK_RADIO = 1,
    BLOCK_MSG
};

new g_pCvar;

new const g_szFireInTheHole[] = "#Fire_in_the_hole";
new const g_szMradFire[] = "%!MRAD_FIREINHOLE";

public plugin_init( ) {
    register_plugin( "'Fire in the hole' blocker", "1.0", "xPaw" );
    
    g_pCvar = register_cvar( "sv_fith_block", "3" );
    
    register_message( get_user_msgid( "TextMsg" ),   "MessageTextMsg" );
    register_message( get_user_msgid( "SendAudio" ), "MessageSendAudio" );
}

public MessageTextMsg( )
{
    //if(get_msg_args() != 5)
    //    return
        
    static szMsg[2][20]
    get_msg_arg_string(3, szMsg[0], charsmax(szMsg[]))
    get_msg_arg_string(5, szMsg[1], charsmax(szMsg[]))
    
    if(equal(szMsg[0], "#Game_radio") && !equal(szMsg[1], "#Fire_in_the_hole"))
        set_msg_arg_string(3, "^x03%s1 ^x01(Radio): %s2")

    return ( get_msg_args( ) == 5 && IsBlocked( BLOCK_MSG ) ) ? GetReturnValue( 5, g_szFireInTheHole ) : PLUGIN_CONTINUE;
}
public MessageSendAudio( )
    return IsBlocked( BLOCK_RADIO ) ? GetReturnValue( 2, g_szMradFire ) : PLUGIN_CONTINUE;

GetReturnValue( const iParam, const szString[ ] ) {
    new szTemp[ 18 ];
    get_msg_arg_string( iParam, szTemp, 17 );
    
    return ( equal( szTemp, szString ) ) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

bool:IsBlocked( const iType )
    return bool:( get_pcvar_num( g_pCvar ) & iType );