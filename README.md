# Life RPG – Quản Lý Trẻ Em Có Tính Gamification

## 1. Tên đề tài
**Life RPG – Ứng dụng quản lý nhiệm vụ trẻ em với xác nhận từ phụ huynh và hệ thống gamification**

---

## 2. Mục tiêu đề tài
- Xây dựng ứng dụng quản lý nhiệm vụ trẻ em được xác nhận bởi phụ huynh theo cơ chế **gamification**.  
- Tạo động lực cho trẻ em hoàn thành nhiệm vụ thông qua hệ thống **EXP, Level, Achievement, Reward**.  
- Cho phép phụ huynh tạo task, theo dõi tiến độ, xác nhận hoàn thành và quản lý tiền thưởng.  
- Xây dựng hệ thống gamification hấp dẫn giúp trẻ em tích cực hoàn thành việc nhà và học tập.  
- Học và thực hành **Flutter + Firebase** theo hướng thực tiễn.

---

## 3. Đối tượng người dùng
- **Phụ huynh:** Người tạo task, xác nhận hoàn thành, quản lý tiền thưởng cho con em.  
- **Trẻ em:** Hoàn thành task được giao, nhận EXP, nâng level, mở khóa achievement, tích lũy tiền thưởng.  
- Các gia đình muốn khuyến khích trẻ em tích cực học tập và hoàn thành việc nhà một cách thú vị.

---

## 4. Phạm vi nghiên cứu / triển khai
- **Frontend:** Flutter  
- **Backend:** Firebase Authentication + Firestore  

### Tính năng chính:
1. **Quản lý Phụ Huynh:** Tạo task, gán cho con em, xác nhận hoàn thành  
2. **Giao Diện Trẻ Em:** Xem task được giao, report hoàn thành, xem EXP và Level  
3. **Hệ thống EXP và Level:** Nhận EXP khi task được xác nhận, lên level  
4. **Achievement & Reward:** Mở khóa thành tựu, nhận tiền thưởng  
5. **Daily Quest:** Nhiệm vụ hằng ngày tự động được tạo  
6. **Leaderboard:** Bảng xếp hạng các con em trong gia đình (nếu có nhiều con)  
7. **Activity Log:** Lịch sử hoạt động, quản lý tiền thưởng

---

## 5. Kế hoạch triển khai chi tiết theo tuần

| Tuần | Công việc | Kết quả dự kiến |
|------|-----------|----------------|
| 1 | Nghiên cứu tài liệu, tìm hiểu Flutter và Firebase | Hiểu cơ bản về Flutter, Firebase, xác định kiến trúc app |
| 2 | Thiết kế UI/UX sơ bộ: Parent Dashboard, Child Dashboard, Task, Profile | Wireframe và mockup cơ bản |
| 3 | Xây dựng cơ sở dữ liệu trên Firestore: Parents, Children, Tasks, Achievements | Database ready với quan hệ parent-child |
| 4 | Code Task Management (Parent tạo task, Child xem + report) | Phụ huynh có thể tạo, xóa, sửa task; Trẻ em xem và báo cáo hoàn thành |
| 5 | Code Verification System (Phụ huynh xác nhận task, cộng EXP) | Phụ huynh xác nhận/từ chối, trẻ em nhận EXP |
| 6 | Code EXP + Level + Achievement System | Trẻ em lên level, mở khóa achievement |
| 7 | Code Reward System + Leaderboard | Quản lý tiền thưởng, bảng xếp hạng |
| 8 | Code Daily Quest + Activity Log | Tự động tạo daily quest, lịch sử hoạt động |
| 9 | Tinh chỉnh UI/UX, thêm animation Level Up, EXP bar | App đẹp mắt, mượt mà, hấp dẫn trẻ em |
| 10 | Kiểm thử toàn bộ chức năng (debug) | App ổn định, fix lỗi |
| 11 | Chuẩn bị báo cáo, slide thuyết trình, demo | Hoàn thiện báo cáo và chuẩn bị nộp/thuyết trình |

---

## 6. Kiến trúc hệ thống

### 6.1 Tầng ứng dụng (Flutter App)
- **UI Layer - Phụ Huynh:** Dashboard, Quản lý Task, Xác nhận Task, Quản lý Con, Profile  
- **UI Layer - Trẻ Em:** Home, Xem Task, Report Hoàn Thành, EXP & Level, Achievement, Profile  
- **Business Logic:** EXP, Level, Achievement, Task Verification, Reward, Parent-Child relationship  
- **State Management:** Provider / Riverpod

### 6.2 Tầng dữ liệu (Firebase)
- **Authentication:** quản lý phụ huynh và trẻ em  
- **Firestore:** lưu Parents, Children, Tasks, Achievements, Verification Logs, Activities, Rewards  
- **Realtime:** cập nhật dữ liệu theo thời gian thực, thông báo xác nhận task

---

## 7. Database Design (Firestore)

- **Parents:** `parentId`, `name`, `email`, `phone`, `avatar`, `createdAt`  
- **Children:** `childId`, `parentId`, `name`, `dateOfBirth`, `avatar`, `exp`, `level`, `totalRewards`, `createdAt`  
- **Tasks:** `taskId`, `childId`, `parentId`, `title`, `description`, `difficulty`, `expReward`, `rewardAmount`, `status` (pending/submitted/approved/rejected), `createdAt`, `submittedAt`, `verifiedAt`  
- **Achievements:** `achievementId`, `name`, `description`, `icon`, `condition`, `reward`  
- **ChildAchievements:** `childId`, `achievementId`, `unlockedAt`  
- **VerificationLogs:** `logId`, `taskId`, `action` (approved/rejected), `verifiedBy`, `timestamp`, `note`  
- **Activities:** `activityId`, `childId`, `type` (task_completed/achievement_unlocked/level_up), `content`, `timestamp`  
- **Rewards:** `rewardId`, `childId`, `amount`, `reason`, `createdAt`  

---

## 8. Luồng hoạt động chính

1. **Phụ huynh tạo Task:** Parent tạo task → Gán cho Child → Hiển thị trong list task của Child  
2. **Trẻ em hoàn thành Task:** Child xem task → Report hoàn thành → Task chuyển sang trạng thái "submitted" → Phụ huynh nhận thông báo  
3. **Phụ huynh xác nhận Task:** Parent xem task đã submit → Xác nhận hoàn thành → Child nhận EXP → Cập nhật Level → Check Achievement → Tạo Activity log  
4. **Leaderboard:** Query Children theo EXP trong cùng gia đình → Hiển thị top  
5. **Reward System:** Parent có thể trao tiền thưởng → Child xem history reward  

---

## 9. Tính năng nâng cao (tùy chọn)
- Dark Mode  
- Notification cho trẻ em nhắc nhở task chưa hoàn thành  
- Notification cho phụ huynh khi child report hoàn thành  
- Animation Level Up / EXP bar  
- Leaderboard hàng tuần, hàng tháng  
- Hệ thống badge, medal cho achievement  
- Parent có thể tạo challenge cho Child với reward đặc biệt  

---

## 10. Kết quả dự kiến
- App **Life RPG** giúp phụ huynh quản lý trẻ em một cách hiệu quả và thú vị.  
- Trẻ em sẽ thấy **động lực hoàn thành task tăng lên** thông qua gamification.  
- Mối quan hệ phụ huynh - con em được cải thiện thông qua hệ thống xác nhận tương tác.  
- Báo cáo và slide trình bày có **sơ đồ hệ thống, mockup UI, flow hoạt động đầy đủ, wireframe giao diện phụ huynh & trẻ em**.  

---

## 11. Tiêu chí đánh giá
- Hoàn thiện chức năng cơ bản (Task, EXP, Level, Verification)  
- Hệ thống xác nhận task từ phụ huynh hoạt động chính xác  
- Giao diện phụ huynh và trẻ em riêng biệt, phù hợp người dùng  
- UI/UX thân thiện, có animation, hấp dẫn trẻ em  
- Code rõ ràng, kiến trúc chuẩn, quản lý quan hệ parent-child tốt  
- Demo trơn tru, báo cáo chi tiết, slide minh họa hệ thống xác nhận