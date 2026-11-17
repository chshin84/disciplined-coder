"""턴 목록이 가리키는 원본 세션 파일을 <DC_EVAL_HOME>/replay/sessions-backup/<프로젝트 폴더 이름>/<파일 이름> 에 복사한다.
이미 사본이 있으면 생략한다. Claude Code 가 오래된 세션 파일을 정리해도 재현 시험이 그 턴을 다시 만들 수 있게 하려는 사본이다.
eval_replay.sh 가 생성 전에 실행한다. 턴 세부는 _replay.turn_details 가 찾는 곳에서 읽는다.

사용: python backup_sessions.py <턴 목록>
출력: 복사·생략·원본 없음 개수. 원본도 사본도 없는 턴이 있으면 그 턴 ID 를 내고 1 로 끝난다."""
import os
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _replay as R  # noqa: E402


def main(argv):
    if len(argv) != 1:
        print(__doc__.rsplit('사용:', 1)[1])
        return 2
    ids = R.read_ids(argv[0])
    turns = R.turn_details()
    copied = skipped = 0
    lost = []
    for i in ids:
        if i not in turns:
            lost.append(i)
            continue
        src = turns[i]['session_file'].replace(chr(92), '/')
        dest = os.path.join(R.dc_eval(), 'replay', 'sessions-backup', os.path.basename(os.path.dirname(src)), os.path.basename(src))
        if os.path.isfile(dest):
            skipped += 1
        elif os.path.isfile(src):
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            shutil.copy2(src, dest + '.tmp')
            os.replace(dest + '.tmp', dest)
            copied += 1
        else:
            lost.append(i)
    print(f'세션 사본: 복사 {copied}, 이미 있음 {skipped}, 원본과 사본이 모두 없음 {len(lost)}')
    if lost:
        print('원본과 사본이 모두 없는 턴:', ' '.join(lost))
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
