.class public Lcom/revivemc74/prototype/dashboard/MainActivity;
.super Landroid/app/Activity;
.source "MainActivity.smali"

.method public constructor <init>()V
    .locals 0
    invoke-direct {p0}, Landroid/app/Activity;-><init>()V
    return-void
.end method

.method protected onCreate(Landroid/os/Bundle;)V
    .locals 3
    invoke-super {p0, p1}, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V
    new-instance v0, Landroid/webkit/WebView;
    invoke-direct {v0, p0}, Landroid/webkit/WebView;-><init>(Landroid/content/Context;)V
    invoke-virtual {v0}, Landroid/webkit/WebView;->getSettings()Landroid/webkit/WebSettings;
    move-result-object v1
    const/4 v2, 0x1
    invoke-virtual {v1, v2}, Landroid/webkit/WebSettings;->setJavaScriptEnabled(Z)V
    new-instance v1, Lcom/revivemc74/prototype/dashboard/MainActivity$ReturnClient;
    invoke-direct {v1, p0}, Lcom/revivemc74/prototype/dashboard/MainActivity$ReturnClient;-><init>(Lcom/revivemc74/prototype/dashboard/MainActivity;)V
    invoke-virtual {v0, v1}, Landroid/webkit/WebView;->setWebViewClient(Landroid/webkit/WebViewClient;)V
    invoke-virtual {p0, v0}, Landroid/app/Activity;->setContentView(Landroid/view/View;)V
    const-string v1, "file:///android_asset/index.html"
    invoke-virtual {v0, v1}, Landroid/webkit/WebView;->loadUrl(Ljava/lang/String;)V
    return-void
.end method

.method public returnToSip()V
    .locals 2
    invoke-virtual {p0}, Landroid/content/Context;->getPackageManager()Landroid/content/pm/PackageManager;
    move-result-object v0
    const-string v1, "com.meraki.dialer2"
    invoke-virtual {v0, v1}, Landroid/content/pm/PackageManager;->getLaunchIntentForPackage(Ljava/lang/String;)Landroid/content/Intent;
    move-result-object v1
    if-nez v1, :launch
    invoke-virtual {p0}, Landroid/app/Activity;->finish()V
    return-void
    :launch
    invoke-virtual {p0, v1}, Landroid/app/Activity;->startActivity(Landroid/content/Intent;)V
    return-void
.end method

.method public onBackPressed()V
    .locals 0
    invoke-virtual {p0}, Lcom/revivemc74/prototype/dashboard/MainActivity;->returnToSip()V
    return-void
.end method
