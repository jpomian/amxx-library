#include < amxmodx >
#include < fakemeta >

#define RADIO_DELAY 5.0

#define m_flNextRadioGameTime 191

enum _:CvarBits (<<=1) {
    BLOCK_RADIO = 1,
    BLOCK_MSG
};

new g_pCvar,
    g_iMsgSendAudio,
    g_iSendAudioEvent,
    Float:g_flRoundStartGameTime;

new const g_szFireInTheHole[] = "#Fire_in_the_hole";
new const g_szMradFire[] = "%!MRAD_FIREINHOLE";

public plugin_init( ) {
    register_plugin( "ColorChat Radio + FITH Block", "1.0", "Mixtaz" );
    
    g_pCvar = register_cvar( "sv_fith_block", "2" ); // 0 - nic nie jest zablokowane, 1 - audio jest zablokowane, 2 - wiadomosc jest zablokowana, 3 - oba sa zablokowane
    
    register_message( get_user_msgid( "TextMsg" ),   "MessageTextMsg" );
    register_message( get_user_msgid( "SendAudio" ), "MessageSendAudio" );

    register_event( "SendAudio", "EventSendAudio", "b", "2&%!MRAD_" );
    register_logevent( "EventRoundStart", 2, "1=Round_Start" );

    g_iMsgSendAudio = get_user_msgid( "SendAudio" );
}

public MessageTextMsg( )
{    
    if( get_msg_args( ) != 5 || get_msg_arg_int( 1 ) != 5 )
        return PLUGIN_CONTINUE;

    static szMsg[2][20];
    get_msg_arg_string(3, szMsg[0], charsmax(szMsg[]))
    get_msg_arg_string(5, szMsg[1], charsmax(szMsg[]))
    
    if(equal(szMsg[0], "#Game_radio") && !equal(szMsg[1], g_szFireInTheHole))
        set_msg_arg_string(3, "^x03%s1 ^x01(Radio): %s2")

    return ( get_msg_args( ) == 5 && IsBlocked( BLOCK_MSG ) ) ? GetReturnValue( 5, g_szFireInTheHole ) : PLUGIN_CONTINUE;
}

public EventSendAudio( const id )
{
	if( id != read_data( 1 ) ) return;
	
	new Float:flGameTime = get_gametime( );
	
	if( flGameTime != g_flRoundStartGameTime )
		set_pdata_float( id, m_flNextRadioGameTime, flGameTime + RADIO_DELAY );
}

public EventRoundStart( )
{
	g_flRoundStartGameTime = get_gametime( );
	
	if( !g_iSendAudioEvent )
		g_iSendAudioEvent = register_message( g_iMsgSendAudio, "SendAudioListener" );
}

public SendAudioListener( )
{
	if( g_flRoundStartGameTime != get_gametime( ) )
	{
		unregister_message( g_iMsgSendAudio, g_iSendAudioEvent );
		
		g_iSendAudioEvent = 0;
		
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_HANDLED;
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