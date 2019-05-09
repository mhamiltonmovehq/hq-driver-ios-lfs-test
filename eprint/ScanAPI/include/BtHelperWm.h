// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the BTHELPERWM_EXPORTS
// symbol defined on the command line. this symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// BTHELPERWM_API functions as being imported from a DLL, whereas this DLL sees symbols
// defined with this macro as being exported.

#ifdef __cplusplus
  extern "C" {
#endif

#define BTSTACK_UNKNOWN		0
#define BTSTACK_MICROSOFT	1
#define BTSTACK_WIDCOMM		2
#define BTSTACK_TOSHIBA		3

typedef struct {
	TCHAR szPortName[20];
	TCHAR szPortDescription[128];
	TCHAR szFriendlyName[256];
}BTPORTINFO, *PBTPORTINFO;

// Defines representing errors that could occur while getting COM port lists from the OS

#define PLE_INVALIDHANDLE	-1
#define PLE_ENUMFAILED		-2
#define	PLE_UNKNOWNSTACK	-7

BOOL IsAdmin();
int GetActiveBtStack(HWND hParent);
PBYTE GetBdAddr();
int GetInboundComPorts(PBTPORTINFO* pPortInfo);
void FreePortInfo(PBTPORTINFO pPortInfo);
BOOL LaunchPortCreationDialog();
BOOL StackIsRunning();

#ifdef __cplusplus
  }
#endif

