/*
 * Title:
 * BtHelper.h
 * 
 * Copyright (c) 2010 Socket Mobile Inc.
 * All rights reserved.
 *
 * Description:
 * Public include header file for the Bluetooth Helper library.
 *
 * Revision 	Who 		History
 * 07/08/10 	GLC 		Genesis
 *
 */

#pragma once

#ifdef BTHELPER_EXPORTS
#ifdef WINCE
// we already have a .def file for exporting the function
// in Windows Mobile configuration
#define BTHELPER_API
#else
#define BTHELPER_API __declspec(dllexport)
#endif
#else
#define BTHELPER_API __declspec(dllimport)
#endif

#ifdef __cplusplus
  extern "C" {
#endif

// Defines representing the current Bluetooth Stack

#define BTSTACK_UNKNOWN		0
#define BTSTACK_MICROSOFT	1
#define BTSTACK_WIDCOMM		2
#define BTSTACK_TOSHIBA		3
#define	BTSTACK_GENERIC		4	// Just a 'com' port manually setup

// Defines representing errors that could occur while getting COM port lists from the OS

#define PLE_SUCCESS				0
#define PLE_INVALIDHANDLE		-1
#define PLE_ENUMFAILED			-2
#define PLE_GETPROP1FAILED		-3
#define PLE_GETPROP2FAILED		-4
#define PLE_NULLPOINTER			-5
#define PLE_TOSHIBAFAIL			-6
#define	PLE_UNKNOWNSTACK		-7
#define PLE_INVALIDPARAMETER	-8


typedef struct {
	TCHAR szPortName[20];
	TCHAR szPortDescription[128];
	TCHAR szFriendlyName[256];
}BTPORTINFO, *PBTPORTINFO;

BTHELPER_API BOOL IsAdmin();
BTHELPER_API int GetActiveBtStack(HWND hParent);
BTHELPER_API const PBYTE GetBdAddr();
BTHELPER_API int GetInboundComPorts(PBTPORTINFO* pPortInfo);
BTHELPER_API int GetOutboundComPorts(PBTPORTINFO* pPortInfo);
BTHELPER_API void FreePortInfo(PBTPORTINFO pPortInfo);
BTHELPER_API BOOL LaunchPortCreationDialog();
BTHELPER_API BOOL StackIsRunning();
BTHELPER_API LPCWSTR GetGenericStackName();
BTHELPER_API BOOL IsNewPortEx(const int iPortIndex, PBTPORTINFO* pPortInfoPtr, LPCTSTR lpszPortName);

#ifdef __cplusplus
  }
#endif

