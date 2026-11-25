.class public Lcom/revivemc74/prototype/dashboard/MainActivity$ReturnClient;
.super Landroid/webkit/WebViewClient;
.source "MainActivity$ReturnClient.smali"

.field private owner:Lcom/revivemc74/prototype/dashboard/MainActivity;

.method public constructor <init>(Lcom/revivemc74/prototype/dashboard/MainActivity;)V
    .locals 0
    invoke-direct {p0}, Landroid/webkit/WebViewClient;-><init>()V
    iput-object p1, p0, Lcom/revivemc74/prototype/dashboard/MainActivity$ReturnClient;->owner:Lcom/revivemc74/prototype/dashboard/MainActivity;
    return-void
.end method

.method public shouldOverrideUrlLoading(Landroid/webkit/WebView;Ljava/lang/String;)Z
    .locals 1
    const-string v0, "sipreturn:"
    invoke-virtual {p2, v0}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
    move-result v0
    if-eqz v0, :continue
    iget-object v0, p0, Lcom/revivemc74/prototype/dashboard/MainActivity$ReturnClient;->owner:Lcom/revivemc74/prototype/dashboard/MainActivity;
    invoke-virtual {v0}, Lcom/revivemc74/prototype/dashboard/MainActivity;->returnToSip()V
    const/4 v0, 0x1
    return v0
    :continue
    const/4 v0, 0x0
    return v0
.end method
