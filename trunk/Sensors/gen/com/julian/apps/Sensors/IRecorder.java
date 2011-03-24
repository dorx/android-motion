/*
 * This file is auto-generated.  DO NOT MODIFY.
 * Original file: /Users/weidai/Dropbox/2010W_CS141b_DistributedComputationLab/matt/Sensors/src/com/julian/apps/Sensors/IRecorder.aidl
 */
package com.julian.apps.Sensors;
public interface IRecorder extends android.os.IInterface
{
/** Local-side IPC implementation stub class. */
public static abstract class Stub extends android.os.Binder implements com.julian.apps.Sensors.IRecorder
{
private static final java.lang.String DESCRIPTOR = "com.julian.apps.Sensors.IRecorder";
/** Construct the stub at attach it to the interface. */
public Stub()
{
this.attachInterface(this, DESCRIPTOR);
}
/**
 * Cast an IBinder object into an com.julian.apps.Sensors.IRecorder interface,
 * generating a proxy if needed.
 */
public static com.julian.apps.Sensors.IRecorder asInterface(android.os.IBinder obj)
{
if ((obj==null)) {
return null;
}
android.os.IInterface iin = (android.os.IInterface)obj.queryLocalInterface(DESCRIPTOR);
if (((iin!=null)&&(iin instanceof com.julian.apps.Sensors.IRecorder))) {
return ((com.julian.apps.Sensors.IRecorder)iin);
}
return new com.julian.apps.Sensors.IRecorder.Stub.Proxy(obj);
}
public android.os.IBinder asBinder()
{
return this;
}
@Override public boolean onTransact(int code, android.os.Parcel data, android.os.Parcel reply, int flags) throws android.os.RemoteException
{
switch (code)
{
case INTERFACE_TRANSACTION:
{
reply.writeString(DESCRIPTOR);
return true;
}
case TRANSACTION_isRecording:
{
data.enforceInterface(DESCRIPTOR);
boolean _result = this.isRecording();
reply.writeNoException();
reply.writeInt(((_result)?(1):(0)));
return true;
}
case TRANSACTION_isReady:
{
data.enforceInterface(DESCRIPTOR);
boolean _result = this.isReady();
reply.writeNoException();
reply.writeInt(((_result)?(1):(0)));
return true;
}
case TRANSACTION_getFilename:
{
data.enforceInterface(DESCRIPTOR);
java.lang.String _result = this.getFilename();
reply.writeNoException();
reply.writeString(_result);
return true;
}
case TRANSACTION_startRecording:
{
data.enforceInterface(DESCRIPTOR);
java.lang.String _arg0;
_arg0 = data.readString();
this.startRecording(_arg0);
reply.writeNoException();
return true;
}
case TRANSACTION_stopRecording:
{
data.enforceInterface(DESCRIPTOR);
this.stopRecording();
reply.writeNoException();
return true;
}
}
return super.onTransact(code, data, reply, flags);
}
private static class Proxy implements com.julian.apps.Sensors.IRecorder
{
private android.os.IBinder mRemote;
Proxy(android.os.IBinder remote)
{
mRemote = remote;
}
public android.os.IBinder asBinder()
{
return mRemote;
}
public java.lang.String getInterfaceDescriptor()
{
return DESCRIPTOR;
}
/**
     * Returns whether this recorder is currently recording.
     * @return True if the recorder is currently recording, False otherwise.
     */
public boolean isRecording() throws android.os.RemoteException
{
android.os.Parcel _data = android.os.Parcel.obtain();
android.os.Parcel _reply = android.os.Parcel.obtain();
boolean _result;
try {
_data.writeInterfaceToken(DESCRIPTOR);
mRemote.transact(Stub.TRANSACTION_isRecording, _data, _reply, 0);
_reply.readException();
_result = (0!=_reply.readInt());
}
finally {
_reply.recycle();
_data.recycle();
}
return _result;
}
/**
     * Returns whether the service has loaded its saved data.
     * @return whether the service has loaded its saved data.
     */
public boolean isReady() throws android.os.RemoteException
{
android.os.Parcel _data = android.os.Parcel.obtain();
android.os.Parcel _reply = android.os.Parcel.obtain();
boolean _result;
try {
_data.writeInterfaceToken(DESCRIPTOR);
mRemote.transact(Stub.TRANSACTION_isReady, _data, _reply, 0);
_reply.readException();
_result = (0!=_reply.readInt());
}
finally {
_reply.recycle();
_data.recycle();
}
return _result;
}
/**
     * Returns the name of the file to which this recorder is recording.
     * @return The name of the file to which this recorder is recording.
     */
public java.lang.String getFilename() throws android.os.RemoteException
{
android.os.Parcel _data = android.os.Parcel.obtain();
android.os.Parcel _reply = android.os.Parcel.obtain();
java.lang.String _result;
try {
_data.writeInterfaceToken(DESCRIPTOR);
mRemote.transact(Stub.TRANSACTION_getFilename, _data, _reply, 0);
_reply.readException();
_result = _reply.readString();
}
finally {
_reply.recycle();
_data.recycle();
}
return _result;
}
/**
     * Starts recording to a file with the given filename.
     * @param filename The filename of the file to which to record.
     */
public void startRecording(java.lang.String filename) throws android.os.RemoteException
{
android.os.Parcel _data = android.os.Parcel.obtain();
android.os.Parcel _reply = android.os.Parcel.obtain();
try {
_data.writeInterfaceToken(DESCRIPTOR);
_data.writeString(filename);
mRemote.transact(Stub.TRANSACTION_startRecording, _data, _reply, 0);
_reply.readException();
}
finally {
_reply.recycle();
_data.recycle();
}
}
/**
     * Stops recording.
     */
public void stopRecording() throws android.os.RemoteException
{
android.os.Parcel _data = android.os.Parcel.obtain();
android.os.Parcel _reply = android.os.Parcel.obtain();
try {
_data.writeInterfaceToken(DESCRIPTOR);
mRemote.transact(Stub.TRANSACTION_stopRecording, _data, _reply, 0);
_reply.readException();
}
finally {
_reply.recycle();
_data.recycle();
}
}
}
static final int TRANSACTION_isRecording = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
static final int TRANSACTION_isReady = (android.os.IBinder.FIRST_CALL_TRANSACTION + 1);
static final int TRANSACTION_getFilename = (android.os.IBinder.FIRST_CALL_TRANSACTION + 2);
static final int TRANSACTION_startRecording = (android.os.IBinder.FIRST_CALL_TRANSACTION + 3);
static final int TRANSACTION_stopRecording = (android.os.IBinder.FIRST_CALL_TRANSACTION + 4);
}
/**
     * Returns whether this recorder is currently recording.
     * @return True if the recorder is currently recording, False otherwise.
     */
public boolean isRecording() throws android.os.RemoteException;
/**
     * Returns whether the service has loaded its saved data.
     * @return whether the service has loaded its saved data.
     */
public boolean isReady() throws android.os.RemoteException;
/**
     * Returns the name of the file to which this recorder is recording.
     * @return The name of the file to which this recorder is recording.
     */
public java.lang.String getFilename() throws android.os.RemoteException;
/**
     * Starts recording to a file with the given filename.
     * @param filename The filename of the file to which to record.
     */
public void startRecording(java.lang.String filename) throws android.os.RemoteException;
/**
     * Stops recording.
     */
public void stopRecording() throws android.os.RemoteException;
}
