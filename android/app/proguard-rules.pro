# 광고 SDK(play-services-ads)가 쓰는 WorkManager 2.7 / Room 2.2는
# Room DB 구현 클래스(WorkDatabase_Impl 등)를 리플렉션으로 생성하는데,
# 이들 라이브러리의 보존 규칙은 R8 full mode에서 기본 생성자를 지켜주지 않아
# 릴리스 빌드가 실행 즉시 종료된다. 생성자를 명시적으로 보존한다.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
